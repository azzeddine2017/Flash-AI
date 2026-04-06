/*
==============================================================================
    FLASH AI - Deep Agent Style CLI
    Main Entry Point - v2.0
==============================================================================
*/
load "src/loadFiles.ring"


func main {
    if len(sysargv) >= 3
        chdir(sysargv[3])
    ok
    new oApp { run() }
}

class oApp

    oUIManager  = new UIManager()
    oSmartAgent = new SmartAgent()
    oCoreAgent  = new CoreAgent()
    
    # --- Application State ---
    bRunning    = true
    cInput      = ""
    nTurnTokens = 0

    # --- Command History ---
    aCommandHistory = []
    nHistoryIndex   = 0
    MAX_HISTORY     = 50

    # --- Tab State ---
    cTabPrefix  = ""
    aTabMatches = []
    nTabIndex   = 0

    func run {
        oCoreAgent.setSmartAgent(oSmartAgent)
        oCoreAgent.setFrontend(oUIManager)
        
        prepareConsole()

        # Tell UI how many tools are loaded
        oUIManager.setToolsCount(oCoreAgent.getToolsCount())

        oUIManager.showHeader()

        # Auth check loop for starting up
        while not oCoreAgent.hasValidAPIKey()
            ? ""
            setColor(YELLOW)
            ? "  [*] No valid API Key found for provider: " + oCoreAgent.getConfig()[2][2]
            setColor(WHITE)
            see "  Please enter your API Key (or type 'exit' to quit): "
            give cKey
            cCleanKey = ""
            for i = 1 to len(cKey)
                nA = ascii(cKey[i])
                if (nA >= 48 and nA <= 57) or (nA >= 65 and nA <= 90) or (nA >= 97 and nA <= 122) or nA = 45 or nA = 95
                    cCleanKey += cKey[i]
                ok
            next
            cKey = cCleanKey
            
            if lower(cKey) = "exit"
                bRunning = false
                exit
            ok
            if cKey != ""
                oCoreAgent.saveAPIKey(cKey)
                oUIManager.showSuccess("API Key saved successfully to config/api_keys.json!")
                sleep(1)
                oUIManager.showHeader()
            ok
        end

        while bRunning {
            # deepagents-style prompt: | >
            oUIManager.showPrompt()

            handleInput()

            if bRunning and trim(cInput) != ""
                # Save to command history
                addToHistory(cInput)
                processCommand(cInput)
            ok
        }
        cleanupConsole()
    }

    func prepareConsole {
        setConsoleTitle("FLASH AI v2.0 — Deep Agent Terminal")
        showCursor()
    }

    func cleanupConsole {
        ? ""
        setColor(YELLOW)
        ? "  Session ended. Goodbye!"
        resetColor()
    }

    # ===================================================================
    # Enhanced Input Handler with history, arrow keys, and shortcuts
    # ===================================================================
    func handleInput {
        cInput = ""
        nCursorPos = 0
        while true
            if kbhit()
                nKey = getKey()
                if nKey != 9 and nKey != 224
                    cTabPrefix = ""
                    aTabMatches = []
                ok
                switch nKey
                    on KEY_ENTER or nKey = 10 or nKey = 13
                        # If more characters are available immediately, it's likely a paste
                        sleep(0.02)
                        if kbhit()
                            # Check for \r\n sequence to avoid double newlines
                            if nKey = 13
                                nNext = getKey()
                                # If it was \r followed by \n (10), we only add one newline
                                if nNext = 10
                                    cInput += nl
                                    see nl
                                    nCursorPos++
                                    loop
                                ok
                                # If it wasn't \n (10), put it into input and continue
                                cInput += nl + char(nNext)
                                see nl + char(nNext)
                                nCursorPos += 2
                                loop
                            ok
                            cInput += nl
                            see nl
                            nCursorPos++
                            loop
                        ok
                        nl
                        exit
                    on KEY_ESCAPE
                        bRunning = false
                        exit
                    on 8, 127  # Backspace
                        if nCursorPos > 0
                            cInput = "" + cInput # Ensure string
                            if nCursorPos = len(cInput)
                                cInput = left(cInput, len(cInput)-1)
                                see char(8) + char(27) + "[K"
                            else
                                cInput = left(cInput, nCursorPos-1) + substr(cInput, nCursorPos+1)
                                replaceInputLine(cInput)
                                see char(27) + "[" + (len(cInput) - nCursorPos + 1) + "D"
                            ok
                            nCursorPos--
                            # Reset Tab State on text change
                            cTabPrefix = ""
                            aTabMatches = []
                        ok
                    on 224  # Special key prefix (Windows)
                        if kbhit()
                            nSpecial = getKey()
                            switch nSpecial
                                on 72  # Up arrow - history previous
                                    if len(aCommandHistory) > 0 and nHistoryIndex > 1
                                        nHistoryIndex--
                                        replaceInputLine(aCommandHistory[nHistoryIndex])
                                        nCursorPos = len(cInput)
                                    ok
                                on 80  # Down arrow - history next
                                    if nHistoryIndex < len(aCommandHistory)
                                        nHistoryIndex++
                                        replaceInputLine(aCommandHistory[nHistoryIndex])
                                        nCursorPos = len(cInput)
                                    elseif nHistoryIndex = len(aCommandHistory)
                                        nHistoryIndex++
                                        replaceInputLine("")
                                        nCursorPos = 0
                                    ok
                                on 75  # Left arrow
                                    if nCursorPos > 0
                                        nCursorPos--
                                        see char(8)
                                    ok
                                on 77  # Right arrow
                                    if nCursorPos < len(cInput)
                                        see cInput[nCursorPos+1]
                                        nCursorPos++
                                    ok
                                on 71  # Home key
                                    for i = 1 to nCursorPos
                                        see char(8)
                                    next
                                    nCursorPos = 0
                                on 79  # End key
                                    if nCursorPos < len(cInput)
                                        see substr(cInput, nCursorPos+1)
                                        nCursorPos = len(cInput)
                                    ok
                                on 83  # Delete key
                                    if nCursorPos < len(cInput)
                                        cInput = left(cInput, nCursorPos) + substr(cInput, nCursorPos+2)
                                        see char(27) + "[K" + substr(cInput, nCursorPos+1)
                                        see char(27) + "[" + (len(cInput) - nCursorPos) + "D"
                                    ok
                            off
                        ok
                    on 9  # Tab - disabled
                        # Tab autocomplete removed by user request
                    other
                        if nKey = 47 and cInput = ""
                            cChoice = handleCommandMenu()
                            if cChoice != ""
                                cInput = cChoice
                                nCursorPos = len(cInput)
                                see cInput
                            ok
                            loop
                        ok
                        
                        if nKey >= 32 and nKey <= 255
                            cInput = "" + cInput # Ensure string type
                            
                            # For Unicode/Arabic safety, we update the buffer and redraw the WHOLE line
                            # This prevents fragmenting multi-byte characters in the terminal display
                            if nCursorPos = len(cInput)
                                cInput += char(nKey)
                            else
                                # Insert at cursor position
                                cInput = left(cInput, nCursorPos) + char(nKey) + substr(cInput, nCursorPos+1)
                            ok
                            
                            nCursorPos++
                            replaceInputLine(cInput)
                            
                            # Move cursor back if we were inserting in the middle
                            if nCursorPos < len(cInput)
                                see char(27) + "[" + (len(cInput) - nCursorPos) + "D"
                            ok
                            
                            # Reset Tab State on text change
                            cTabPrefix = ""
                            aTabMatches = []
                        
                        

                        ok
                off
            ok
            sleep(0.01) # Reduce CPU usage
        end
    }

    # Replace the current input line on screen
    func replaceInputLine cNewInput {
        see char(27) + "[2K" + char(13)
        oUIManager.showPrompt()
        cInput = cNewInput
        see cInput
    }

    # ===================================================================
    # Command History Management
    # ===================================================================
    func addToHistory cCmd {
        cCmd = trim(cCmd)
        if cCmd = "" return ok
        # Avoid duplicating the last command
        if len(aCommandHistory) > 0 and aCommandHistory[len(aCommandHistory)] = cCmd
            nHistoryIndex = len(aCommandHistory) + 1
            return
        ok
        aCommandHistory + cCmd
        if len(aCommandHistory) > MAX_HISTORY
            del(aCommandHistory, 1)
        ok
        nHistoryIndex = len(aCommandHistory) + 1
    }

    # ===================================================================
    # Interactive Command Menu
    # ===================================================================
    func handleCommandMenu {
        aMenuOptions = [
            ["/plan"        , "Agent analyzes plan only (no execution)"],
            ["/execute"     , "Agent executes tools immediately"],
            ["/auto"        , "Fully autonomous FSM active"],
            ["/lang "       , "Change language (ar/en)"],
            ["/theme "      , "Change UI Theme (deepagents/hacker/light)"],
            ["/multi"       , "Enter Multi-line editor mode"],
            ["/workspace "  , "Change active workspace directory"],
            ["/model "      , "Change AI model"],
            ["/provider "   , "Switch AI provider (gemini/openai/claude/openrouter)"],
            ["/debug "      , "Toggle debug mode"],
            ["/tokens"      , "Show token usage"],
            ["/history "    , "Show last n user commands"],
            ["/chatlog"     , "View current conversation log"],
            ["/save "       , "Save session (json/txt/md)"],
            ["/load "       , "Load a saved session"],
            ["/sessions"    , "List saved sessions"],
            ["/tools"       , "List available AI tools"],
            ["/config"      , "Show current configuration"],
            ["/set "        , "Change a setting"],
            ["/run "        , "Execute a Ring file"],
            ["/authorize"   , "Grant full session permissions"]
        ]
        nSelected = 1
        bMenuRunning = true

        # Print empty lines to ensure screen has space, avoiding scroll issues when drawing menu
        cNLs = nl
        for i = 1 to len(aMenuOptions)  cNLs += nl next
        see cNLs
        # Move cursor back up
        see char(27) + "[" + (len(aMenuOptions) + 1) + "A"

        see char(27) + "7" # Save position (ANSI)

        while bMenuRunning
            see char(27) + "8" # Restore position (ANSI)
            for i = 1 to len(aMenuOptions)
                see nl
                if i = nSelected
                    setColor(CYAN)
                    see "  > " + left(aMenuOptions[i][1] + copy(" ", 20), 20)
                    setColor(DARKGREY)
                    see "- " + aMenuOptions[i][2] + copy(" ", 40)
                else
                    setColor(DARKGREY)
                    see "    " + left(aMenuOptions[i][1] + copy(" ", 20), 20)
                    see "- " + aMenuOptions[i][2] + copy(" ", 40)
                ok
            next
            resetColor()

            while not kbhit() sleep(0.01) end
            nSpecial = getKey()

            if nSpecial = KEY_ENTER or nSpecial = 13 or nSpecial = 10
                bMenuRunning = false
                see char(27) + "8"
                for i = 1 to len(aMenuOptions)
                    see nl + copy(" ", tCols() - 1)
                next
                see char(27) + "8"
                return aMenuOptions[nSelected][1]
            elseif nSpecial = KEY_ESCAPE or nSpecial = 27
                bMenuRunning = false
                see char(27) + "8"
                for i = 1 to len(aMenuOptions)
                    see nl + copy(" ", tCols() - 1)
                next
                see char(27) + "8"
                return "/"
            elseif nSpecial = 8 or nSpecial = 127 # Backspace
                bMenuRunning = false
                see char(27) + "8"
                for i = 1 to len(aMenuOptions)
                    see nl + copy(" ", tCols() - 1)
                next
                see char(27) + "8"
                return ""
            elseif nSpecial = 224 # Arrows Windows
                if kbhit()
                    nDir = getKey()
                    if nDir = 72 or nDir = KEY_UP
                        if nSelected > 1 nSelected-- ok
                    elseif nDir = 80 or nDir = KEY_DOWN
                        if nSelected < len(aMenuOptions) nSelected++ ok
                    ok
                ok
            elseif nSpecial = KEY_UP
                if nSelected > 1 nSelected-- ok
            elseif nSpecial = KEY_DOWN
                if nSelected < len(aMenuOptions) nSelected++ ok
            ok
        end
        return "/"
    }

    # ===================================================================
    # Tab Completion Data
    # ===================================================================
    func getTabMatches cPartial {
        if cPartial = "" return [] ok

        aSlashCmds = ["/model", "/provider", "/debug", "/tokens", "/history",
                      "/save", "/load", "/sessions", "/tools", "/clear", 
                      "/config", "/set", "/run", "/help", "/authorize", "/cmd", "/chatlog", "/multi", "/theme", "/lang", "/workspace",
                      "/plan", "/execute", "/auto"]
        
        aBuiltinCmds = ["help", "clear", "cls", "exit", "quit", "ls", "dir", 
                        "files", "read"]

        aAllCmds = []
        for c in aSlashCmds  aAllCmds + c next
        for c in aBuiltinCmds  aAllCmds + c next

        aMatches = []
        for cCmd in aAllCmds
            if left(lower(cCmd), len(cPartial)) = cPartial
                aMatches + cCmd
            ok
        next
        return aMatches
    }

    # ===================================================================
    # Shadow Text Auto-suggestions
    # ===================================================================
    func getShadowMatch cInput {
        if trim(cInput) = "" return "" ok
        cInputLower = lower(cInput)
        
        # Check command history (most recent first)
        for i = len(aCommandHistory) to 1 step -1
            if left(lower(aCommandHistory[i]), len(cInputLower)) = cInputLower
                return substr(aCommandHistory[i], len(cInputLower) + 1)
            ok
        next
        
        return ""
    }

    # ===================================================================
    # Command Processing - Extended with slash commands
    # ===================================================================
    func processCommand cCommand {
        cLowerCmd = lower(trim(cCommand))

        # --- Internal Commands ---
        switch cLowerCmd
            on "exit" on "quit"
                bRunning = false
                return
            on "help" on "/help"
                showExtendedHelp("")
                return
            on "clear" on "cls" on "/clear"
                oUIManager.setToolsCount(oCoreAgent.getToolsCount())
                oUIManager.showHeader()
                return
            on "ls" on "dir" on "files"
                runInternalTool("list_files", ["."])
                return
            on "/tools"
                showToolsList()
                return
            on "/tokens"
                showTokenInfo()
                return
            on "/sessions"
                showSessions()
                return
            on "/chatlog"
                aHist = oCoreAgent.getConversationHistory()
                oUIManager.displayChatLog(aHist)
                return
            on "/config"
                showConfig()
                return
            on "/authorize"
                oSmartAgent.setSessionAuthorized(true)
                oUIManager.showSuccess("Full session authorization granted. Tools will execute without confirmation.")
                return
            
            on "/cmd"
                # Do nothing here, handled by prefix check below
                return
            on "/multi"
                handleMultiLineInput()
                return
            on "/plan"
                oSmartAgent.cExecutionMode = "plan"
                oUIManager.showSuccess("Mode changed to [ PLANNING ]. Agent will pause for approval after analysis.")
                return
            on "/execute"
                oSmartAgent.cExecutionMode = "execute"
                oSmartAgent.bWaitingForApproval = false
                oUIManager.showSuccess("Mode changed to [ EXECUTION ]. Tools will run immediately.")
                return
            on "/auto"
                oSmartAgent.cExecutionMode = "auto"
                oSmartAgent.bWaitingForApproval = false
                oUIManager.showSuccess("Mode changed to [ AUTO ]. Fully autonomous FSM active.")
                return
        off
        
        if left(cLowerCmd, 7) = "/theme "
            cTheme = trim(substr(cCommand, 8))
            oUIManager.setTheme(cTheme)
            oUIManager.showHeader()
            oUIManager.showSuccess("Theme changed to: " + cTheme)
            return
        ok

        if left(cLowerCmd, 11) = "/workspace "
            cPath = trim(substr(cCommand, 12))
            chdir(cPath)
            oUIManager.cCurrentDir = CurrentDir()
            oUIManager.showHeader()
            oUIManager.showSuccess("Workspace changed to: " + CurrentDir())
            return
        ok

        if left(cLowerCmd, 6) = "/lang "
            cLang = trim(substr(cCommand, 7))
            oUIManager.setLanguage(cLang)
            oUIManager.showHeader()
            oUIManager.showSuccess("Language changed to: " + cLang)
            return
        ok

        # --- Prefix-based / commands ---
        if left(cLowerCmd, 5) = "/cmd "
            cExec = trim(substr(cCommand, 6))
            if cExec != ""
                oTools = new AgentTools()
                oRes = oTools.executeCommand(cExec)
                ? oRes[:message]
            else
                oUIManager.showError("Command is required.")
            ok
            return
        ok

        if left(cLowerCmd, 5) = "read "
            cFile = trim(substr(cCommand, 6))
            if cFile != ""
                oRes = readFile(cFile)
                if oRes[:success]
                    # We strip the "File content:\n" prefix if present from AgentTools.readFile
                    cContent = oRes[:message]
                    if left(cContent, 13) = "File content:"
                        cContent = substr(cContent, substr(cContent, nl) + 1)
                    ok
                    oUIManager.displayFileContent(cFile, cContent)
                else
                    oUIManager.showError(oRes[:error])
                ok
            else
                oUIManager.showError("File name is required.")
            ok
            return
        ok

        if left(cLowerCmd, 7) = "/model "
            cModel = trim(substr(cCommand, 8))
            oCoreAgent.setModel(cModel)
            oUIManager.showSuccess("Model changed to: " + cModel)
            return
        ok

        if left(cLowerCmd, 10) = "/provider "
            cProvider = trim(substr(cCommand, 11))
            if oCoreAgent.setProvider(cProvider)
                oUIManager.showSuccess("Provider changed to: " + cProvider)
                
                # Check if it has a valid API key
                while not oCoreAgent.hasValidAPIKey()
                    ? ""
                    setColor(YELLOW)
                    ? "  [*] No valid API Key found for provider: " + oCoreAgent.getConfig()[2][2]
                    setColor(WHITE)
                    see "  Please enter your API Key (or type 'cancel' to ignore): "
                    give cKey
                    
                    cCleanKey = ""
                    for i = 1 to len(cKey)
                        nA = ascii(cKey[i])
                        if (nA >= 48 and nA <= 57) or (nA >= 65 and nA <= 90) or (nA >= 97 and nA <= 122) or nA = 45 or nA = 95
                            cCleanKey += cKey[i]
                        ok
                    next
                    cKey = cCleanKey
                    
                    if lower(cKey) = "cancel"
                        oUIManager.showError("No Key provided. Provider will not work.")
                        exit
                    ok
                    
                    if cKey != ""
                        oCoreAgent.saveAPIKey(cKey)
                        oUIManager.showSuccess("API Key saved successfully!")
                        sleep(1)
                    ok
                end
            else
                oUIManager.showError("Invalid provider. Use: gemini, openai, claude, openrouter")
            ok
            return
        ok

        if left(cLowerCmd, 7) = "/debug "
            cVal = trim(substr(cCommand, 8))
            if cVal = "on" or cVal = "true"
                oCoreAgent.setDebugMode(true)
                oUIManager.showSuccess("Debug mode enabled")
            else
                oCoreAgent.setDebugMode(false)
                oUIManager.showSuccess("Debug mode disabled")
            ok
            return
        ok

        if left(cLowerCmd, 6) = "/save "
            cFormat = lower(trim(substr(cCommand, 7)))
            handleSave(cFormat)
            return
        ok
        if cLowerCmd = "/save"
            handleSave("json")
            return
        ok

        if left(cLowerCmd, 6) = "/load "
            cSessionArg = trim(substr(cCommand, 7))
            cSessionFile = cSessionArg
            
            # Try to parse as index if it's a number
            if len(cSessionArg) <= 4 # Reasonable length for an index
                try
                    nTryIdx = number(cSessionArg)
                    if nTryIdx > 0
                        aPreviews = oCoreAgent.getSessionsWithPreviews()
                        if nTryIdx <= len(aPreviews)
                            cSessionFile = aPreviews[nTryIdx][1][2]
                        ok
                    ok
                catch
                done
            ok
            
            if oCoreAgent.loadSession(cSessionFile)
                oUIManager.showSuccess("Session loaded: " + cSessionFile)
                aHist = oCoreAgent.getConversationHistory()
                oUIManager.displayChatLog(aHist)
            else
                oUIManager.showError("Session not found: " + cSessionArg)
            ok
            return
        ok

        if left(cLowerCmd, 5) = "/run "
            cFile = trim(substr(cCommand, 6))
            runInternalTool("run_ring_code", [cFile])
            return
        ok

        if left(cLowerCmd, 5) = "/set "
            handleSetCommand(trim(substr(cCommand, 6)))
            return
        ok

        if left(cLowerCmd, 6) = "/help "
            cTopic = lower(trim(substr(cCommand, 7)))
            showExtendedHelp(cTopic)
            return
        ok

        if left(cLowerCmd, 9) = "/history "
            cCount = trim(substr(cCommand, 10))
            showHistory(cCount)
            return
        ok
        if cLowerCmd = "/history"
            showHistory("10")
            return
        ok

        # --- Pass to Core Agent ---
        oUIManager.showThinking()
        cContext = "Current Directory: " + CurrentDir() + nl
        oResponse = oCoreAgent.processMessage(cCommand, cContext)

        ? "" # Separator

        if oResponse[:success]
            # Display final message only if not already shown in agentic loop
            # Since SmartAgent already calls displayAIMessage within the loop,
            # we don't need to display it here again.
            
            # Show token usage
            if oResponse[:total_tokens] != null and oResponse[:total_tokens] > 0
                setColor(DARKGREY)
                ? "  [tokens: " + oResponse[:total_tokens] + "]"
                resetColor()
            ok
        else
            oUIManager.showError(oResponse[:error])
        ok
    }

    # ===================================================================
    # Internal Tool Execution
    # ===================================================================
    func runInternalTool cTool, aParams {
        oResult = oCoreAgent.runTool(cTool, aParams)
        if oResult[:success]
            setColor(WHITE)
            ? oResult[:message]
            resetColor()
        else
            oUIManager.showError(oResult[:error])
        ok
    }
    
    # ===================================================================
    # Multi-line Input Editor
    # ===================================================================
    func handleMultiLineInput {
        ? ""
        setColor(YELLOW)
        ? "  [Multi-line Editor] Type your text below. "
        ? "  - Type /send or press ENTER on an empty line twice to submit."
        ? "  - Type /cancel to abort."
        resetColor()
        
        cFullText = ""
        while true
            see "  | "
            give cLine 
            cTrimmed = trim(cLine)
            
            if lower(cTrimmed) = "/cancel"
                ? ""
                setColor(YELLOW)
                ? "  [Editor Cancelled]"
                resetColor()
                return
            ok
            
            if lower(cTrimmed) = "/send"
                exit
            ok
            
            # Submission by double empty enter (standard CLI convention)
            if cTrimmed = "" and right(cFullText, 1) = nl
                exit
            ok
            
            cFullText += cLine + nl
        end
        
        ? ""
        if trim("" + cFullText) != ""
            processCommand(trim("" + cFullText))
        ok
    }

    # ===================================================================
    # Extended Help System
    # ===================================================================
    func showExtendedHelp cTopic {
        ? ""
        switch cTopic
            on ""
                # General help
                setColor(CYAN)
                ? "  FLASH AI v2.0 - Command Reference"
                ? "  " + copy("=", 40)
                ? ""
                setColor(WHITE)
                ? "  Built-in Commands:"
                setColor(LIGHTGREEN)
                ? "    ls / dir / files   - List files in current directory"
                ? "    read <file>        - Read and display file contents"
                ? "    clear / cls        - Clear screen and show header"
                ? "    exit / quit        - Exit FLASH AI"
                ? ""
                setColor(WHITE)
                ? "  Slash Commands:"
                setColor(LIGHTGREEN)
                ? "    /model <name>      - Change AI model"
                ? "    /provider <name>   - Switch AI provider (gemini/openai/claude)"
                ? "    /debug on|off      - Toggle debug mode"
                ? "    /tokens            - Show token usage"
                ? "    /history [n]       - Show last n user commands"
                ? "    /chatlog           - View current conversation log"
                ? "    /save [format]     - Save session (json/txt/md)"
                ? "    /load <session>    - Load a saved session"
                ? "    /sessions          - List saved sessions"
                ? "    /tools             - List available AI tools"
                ? "    /config            - Show current configuration"
                ? "    /set <key> <val>   - Change a setting"
                ? "    /run <file>        - Execute a Ring file"
                ? "    /authorize         - Grant full session permissions"
                ? ""
                setColor(WHITE)
                ? "  AI Capabilities (natural language):"
                setColor(DARKGREY)
                ? "    Analyze code, create/edit files, run commands,"
                ? "    git operations, search in files, project scaffolding"
                ? ""
                setColor(CYAN)
                ? "  Tip: Use /help <topic> for details (e.g. /help tools)"
                ? ""
            on "tools"
                showToolsList()
            on "save"
                setColor(CYAN)
                ? "  /save Command:"
                setColor(WHITE)
                ? "    /save          - Save as JSON (default)"
                ? "    /save json     - Save as JSON"
                ? "    /save txt      - Save as plain text"
                ? "    /save md       - Save as Markdown"
                ? ""
            on "model"
                setColor(CYAN)
                ? "  /model Command:"
                setColor(WHITE)
                ? "    /model gemini-2.0-flash"
                ? "    /model gemini-2.5-pro"
                ? "    /model gemini-3.1-flash-lite-preview"
                ? ""
            on "provider"
                setColor(CYAN)
                ? "  /provider Command:"
                setColor(WHITE)
                ? "    /provider gemini  - Google Gemini"
                ? "    /provider openai  - OpenAI GPT"
                ? "    /provider claude  - Anthropic Claude"
                ? ""
            other
                oUIManager.showError("Unknown help topic: " + cTopic)
        off
        resetColor()
    }

    # ===================================================================
    # Show Available Tools
    # ===================================================================
    func showToolsList {
        aTools = oCoreAgent.getToolsList()
        ? ""
        setColor(CYAN)
        ? "  Available AI Tools (" + len(aTools) + " loaded):"
        ? "  " + copy("-", 50)
        
        cCurrentCat = ""
        for oTool in aTools
            if oTool.category != cCurrentCat
                cCurrentCat = oTool.category
                ? ""
                setColor(YELLOW)
                ? "  [" + upper(cCurrentCat) + "]"
            ok
            setColor(LIGHTGREEN)
            see "    " + oTool.name
            setColor(DARKGREY)
            ? " - " + oTool.description
        next
        ? ""
        resetColor()
    }

    # ===================================================================
    # Show Token Info
    # ===================================================================
    func showTokenInfo {
        aConfig = oCoreAgent.getConfig()
        cModel = getValueFromList(aConfig, "model", "Unknown")
        cMax = getValueFromList(aConfig, "max_tokens", "0")
        
        ? ""
        setColor(CYAN)
        ? "  Token Usage:"
        setColor(WHITE)
        ? "    Total tokens used: " + oCoreAgent.getTotalTokens()
        ? "    Model: " + cModel
        ? "    Max tokens: " + cMax
        ? ""
        resetColor()
    }

    # ===================================================================
    # Show Saved Sessions
    # ===================================================================
    func showSessions {
        aSessions = oCoreAgent.getSessionsList()
        ? ""
        setColor(CYAN)
        ? "  Saved Sessions (" + len(aSessions) + "):"
        setColor(DARKGREY)
        ? "  " + copy("-", 40)
        
        if len(aSessions) = 0
            setColor(DARKGREY)
            ? "    No saved sessions found."
        else
            aPreviews = oCoreAgent.getSessionsWithPreviews()
            nIdx = 0
            for oItem in aPreviews
                nIdx++
                cFile = oItem[1][2]
                cPrv  = oItem[2][2]
                setColor(LIGHTGREEN)
                see "    " + nIdx + ". "
                setColor(WHITE)
                see cPrv
                setColor(DARKGREY)
                ? "  [" + cFile + "]"
            next
        ok
        ? ""
        setColor(DARKGREY)
        ? "  Use /load <filename> to restore a session"
        ? ""
        resetColor()
    }

    # ===================================================================
    # Show Configuration
    # ===================================================================
    func showConfig {
        aConfig = oCoreAgent.getConfig()
        ? ""
        setColor(CYAN)
        ? "  Current Configuration:"
        setColor(DARKGREY)
        ? "  " + copy("-", 40)
        setColor(WHITE)
        for oItem in aConfig
            if len(oItem) = 2
                ? "    " + oItem[1] + ": " + oItem[2]
            ok
        next
        ? ""
        resetColor()
    }

    # ===================================================================
    # Handle Save Command
    # ===================================================================
    func handleSave cFormat {
        cFile = oCoreAgent.saveSession(cFormat)
        if cFile != ""
            oUIManager.showSuccess("Session saved to: " + cFile)
        else
            oUIManager.showError("Unknown format. Use: json, txt, md")
        ok
    }

    # ===================================================================
    # Handle /set Command
    # ===================================================================
    func handleSetCommand cArgs {
        cArgs = trim(cArgs)
        nFirstSpace = substr(cArgs, " ")
        if nFirstSpace = 0
            oUIManager.showError("Usage: /set <key> <value>")
            return
        ok
        
        cKey = lower(trim(left(cArgs, nFirstSpace - 1)))
        cVal = trim(substr(cArgs, nFirstSpace + 1))
        
        switch cKey
            on "agent"
                oSmartAgent.cAgentName = cVal
                oUIManager.showSuccess("Agent name set to: " + cVal)
            on "provider"
                if oCoreAgent.setProvider(lower(cVal))
                    oUIManager.showSuccess("Provider set to: " + lower(cVal))
                else
                    oUIManager.showError("Invalid provider. Use: gemini, openai, claude")
                ok
            on "model"
                oCoreAgent.setModel(cVal)
                oUIManager.showSuccess("Model set to: " + cVal)
            on "temperature"
                oCoreAgent.setTemperature(number(cVal))
                oUIManager.showSuccess("Temperature set to: " + cVal)
            on "max_tokens"
                oCoreAgent.setMaxTokens(number(cVal))
                oUIManager.showSuccess("Max tokens set to: " + cVal)
            on "language"
                oCoreAgent.setLanguage(upper(cVal))
                oUIManager.setLanguage(upper(cVal))
                oUIManager.showSuccess("Language set to: " + upper(cVal))
            on "debug"
                if cVal = "1" or lower(cVal) = "true" or lower(cVal) = "on"
                    oCoreAgent.setDebugMode(true)
                    oUIManager.showSuccess("Debug mode enabled")
                else
                    oCoreAgent.setDebugMode(false)
                    oUIManager.showSuccess("Debug mode disabled")
                ok
            on "session_id"
                oSmartAgent.cSessionId = cVal
                oUIManager.cSessionId = cVal
                oUIManager.showSuccess("Session ID set to: " + cVal)
            on "working_dir"
                try
                    chdir(cVal)
                    oUIManager.cCurrentDir = CurrentDir()
                    oUIManager.cCurrentDir = cVal
                    oUIManager.showSuccess("Working directory changed to: " + CurrentDir())
                catch
                    oUIManager.showError("Could not change directory to: " + cVal)
                done
            on "tools_count"
                oUIManager.showError("tools_count is read-only and cannot be manually set.")
            on "messages"
                oCoreAgent.nMessageCount = number(cVal)
                oUIManager.showSuccess("Message count set to: " + oCoreAgent.nMessageCount)
            other
                oUIManager.showError("Unknown setting. Available: agent, provider, model, temperature, max_tokens, language, debug, session_id, working_dir, messages")
        off
    }

    # ===================================================================
    # Show Command History
    # ===================================================================
    func showHistory cCount {
        nCount = number(cCount)
        if nCount <= 0 nCount = 10 ok
        ? ""
        setColor(CYAN)
        ? "  Command History (last " + nCount + "):"
        setColor(DARKGREY)
        ? "  " + copy("-", 40)
        
        nStart = max(1, len(aCommandHistory) - nCount + 1)
        for i = nStart to len(aCommandHistory)
            setColor(DARKGREY)
            see "  " + i + ". "
            setColor(WHITE)
            ? aCommandHistory[i]
        next
        ? ""
        resetColor()
    }

    func nRows()
        return tRows()
