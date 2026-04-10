# ===================================================================
# UI Manager - FLASH AI Deep Agent Style
# ===================================================================
    

class Formatter
    func colorizeText cText, cTheme
        # Extremely basic markdown code block colorizer for terminal
        aLines = str2list(cText)
        bInCode = false
        cOut = ""
        for i = 1 to len(aLines)
            cLine = aLines[i]
            if left(trim(cLine), 3) = "```"
                bInCode = not bInCode
                cOut += cLine + nl
                loop
            ok
            
            if bInCode
                # Prepend special ansi code or handle in caller?
                # Actually, better to just return the lines and let caller handle state,
                # or we just build a structured list.
            ok
        next
        return cOut

class UIManager

    # --- Configuration ---
    oLoc = new Localization
    oTheme = new ThemeManager
    
    nConsoleWidth    = 80
    nToolsLoaded     = 0
    cSessionId       = ""
    nTokensUsed      = 0
    cCurrentDir      = ""
    cLastMode        = ""
    
    func init {
        nConsoleWidth = tCols()
        cCurrentDir   = CurrentDir()
        cSessionId    = generateSessionId()
        nTokensUsed   = 0
    }

    func setToolsCount n {
        nToolsLoaded = n
    }

    func addTokens n {
        nTokensUsed += n
    }

    func setLanguage cLang {
        oLoc.setLang(cLang)
    }

    func getLanguage() {
        return oLoc.cLang
    }
    
    func setTheme cTheme {
        oTheme.setTheme(cTheme)
    }

    # ===================================================================
    # Main Header
    # ===================================================================
    func showHeader {
        cls()
        nWidth = tCols()
        if nWidth < 60  nWidth = 60  ok

        setColor(oTheme.getPrimary())
        ? ""
        ? "  ███████╗██╗      █████╗ ███████╗██╗  ██╗    █████╗ ██╗"
        ? "  ██╔════╝██║     ██╔══██╗██╔════╝██║  ██║   ██╔══██╗██║"
        ? "  █████╗  ██║     ███████║███████╗███████║   ███████║██║"
        ? "  ██╔══╝  ██║     ██╔══██║╚════██║██╔══██║   ██╔══██║██║"
        ? "  ██║     ███████╗██║  ██║███████║██║  ██║   ██║  ██║██║"
        ? "  ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝  ╚═╝╚═╝"
        ? ""

        # Version right-aligned
        setColor(oTheme.getAccent())
        cVer = "v3.0"
        nPad = nWidth - len(cVer) - 4
        if nPad < 0  nPad = 0  ok
        ? copy(" ", nPad) + cVer

        ? ""
        setColor(oTheme.getAccent())
        see "  [+] "
        setColor(oTheme.getText())
        see "Ring " + version() + " engine active"
        ? ""
        setColor(oTheme.getAccent())
        see "  [+] "
        setColor(oTheme.getText())
        see "AI Provider Interface Active"
        ? ""
        setColor(oTheme.getAccent())
        see "  [+] "
        setColor(oTheme.getText())
        see "Loaded " + nToolsLoaded + " tools"
        ? ""

        setColor(oTheme.getSec())
        ? "  Thread: " + cSessionId
        ? "  Dir: " + cCurrentDir

        ? ""
        setColor(oTheme.getPrimary())
        ? "  " + oLoc.getString("welcome")
        setColor(oTheme.getSec())
        ? "  " + oLoc.getString("help_hint")
        ? ""
        resetColor()
    }

    # ===================================================================
    # User input prompt
    # ===================================================================
    func showPrompt {
        setColor(oTheme.getBorder())
        see "  | "
        setColor(oTheme.getPrimary())
        see "> "
        resetColor()
    }

    # ===================================================================
    # Display AI message (with basic Markdown handling)
    # ===================================================================
     func displayAIMessage cResponse {
        ? ""
        aLines = str2list(cResponse)
        bInCodeBlock = false
        
        for cLine in aLines
            # Handle Code Block Transitions
            if left(trim(cLine), 3) = "```"
                bInCodeBlock = not bInCodeBlock
                setColor(oTheme.getSec())
                ? "  " + char(27)+"[90m" + "├" + copy("─", 4) + " [ CODE ] " + copy("─", 40)
                loop
            ok
            
            # Draw Sidebar
            if bInCodeBlock
                setColor(oTheme.getSec()) # Dark Sidebar for code
                see "  │ "
                printCodeLine(cLine, oTheme)
            else
                setColor(oTheme.getPrimary()) # Blue/Primary sidebar for text
                see "  │ "
                setColor(oTheme.getText())
                printMarkdownLine(cLine, oTheme)
            ok
        next
        resetColor()
    }

    # ===================================================================
    # Display Chat Log
    # ===================================================================
    func displayChatLog aHistory {
        ? ""
        setColor(oTheme.getPrimary())
        ? "  " + oLoc.getString("chat_history")
        ? ""
        for oMsg in aHistory
            if type(oMsg) != "LIST" loop ok
            cRole = "" cContent = ""
            for pair in oMsg
                if type(pair) = "LIST" and len(pair) >= 2
                    if pair[1] = "role" cRole = pair[2] ok
                    if pair[1] = "content" cContent = pair[2] ok
                    if pair[1] = "parts"
                        if type(pair[2]) = "LIST" 
                            for oPart in pair[2]
                                if type(oPart) = "LIST"
                                    for oPPair in oPart
                                        if oPPair[1] = "text" cContent += oPPair[2] ok
                                    next
                                ok
                            next
                        ok
                    ok
                ok
            next
            if trim(cContent) = "" loop ok
            if lower(cRole) = "user"
                setColor(oTheme.getSec())
                see "  ├─ "
                setColor(oTheme.getPrimary())
                see "YOU"
                setColor(oTheme.getSec())
                ? " ─────────────────────────────────"
                setColor(oTheme.getText())
                ? "  " + cContent
            elseif lower(cRole) = "system"
                setColor(oTheme.getSec())
                ? "  [ SYSTEM PROTOCOL ACTIVE ]"
            else
                setColor(oTheme.getSec())
                see "  ├─ "
                setColor(oTheme.getAccent())
                see "FLASH AI"
                setColor(oTheme.getSec())
                ? " ──────────────────────────────"
                
                # Render content blocks
                bInCodeBlock = false
                aLines = str2list(cContent)
                for cLine in aLines
                    if left(trim(cLine), 3) = "```"
                        bInCodeBlock = not bInCodeBlock
                        setColor(oTheme.getSec())
                        ? "  │ " + cLine
                        loop
                    ok
                    
                    setColor(oTheme.getBorder())
                    see "  │ "
                    if bInCodeBlock
                        printCodeLine(cLine, oTheme)
                    else
                        setColor(oTheme.getText())
                        printMarkdownLine(cLine, oTheme)
                    ok
                next
            ok
            ? ""
        next
        resetColor()
    }

    # ===================================================================
    # System Note display (used by Reflection Engine & Telemetry)
    # ===================================================================
    func displaySystemNote(cNote) {
        ? ""
        setColor(oTheme.getSec())
        see "  │ "
        setColor(oTheme.getWarn())
        see "[ SYSTEM NOTE ] "
        setColor(oTheme.getText())
        ? cNote
        resetColor()
    }

    # ===================================================================
    # Tool Action display
    # ===================================================================
    func displayToolAction cToolName, cDetails {
        setColor(DARKGREY)
        see "  │ "
        
        # Using ANSI Color codes for inline badges
        see getANSIBgColor(DARKGREY) + getANSIColor(YELLOW) + " ◆ " + upper(cToolName) + " " + getANSIColor(WHITE)
        resetColor()
        
        setColor(DARKGREY)
        see " → "
        
        setColor(CYAN)
        if len(cDetails) > 50 cDetails = left(cDetails, 47) + "..." ok
        ? cDetails
        resetColor()
    }


    # ===================================================================
    # Line changes visualization
    # ===================================================================
    func displayToolStats cFile, nAdded, nRemoved {
        if islist(cFile) 
            if len(cFile) >= 2 and type(cFile[1]) = "STRING"
                cFile = "" + cFile[2]
            else
                cFile = "[List]"
            ok
        ok
        cFile = "" + cFile
        
        if nAdded = NULL nAdded = 0 ok
        if nRemoved = NULL nRemoved = 0 ok
        
        cAdded = "" + nAdded
        cRemoved = "" + nRemoved
        
        setColor(oTheme.getPrimary())
        see "     " + cFile
        setColor(oTheme.getSec())
        see " [ "
        setColor(oTheme.getAccent())
        see "+" + cAdded + " "
        setColor(oTheme.getError())
        see "-" + cRemoved
        setColor(oTheme.getSec())
        see " ]" + nl
        resetColor()
    }
     
    func showThinking {
        setColor(oTheme.getSec())
        see nl + "  " + oLoc.getString("thinking")
        # Pulse animation (simulated dots)
        for i = 1 to 3
            see "."
            sleep(0.2)
        next
        resetColor()
        ? ""
    }

    # ===================================================================
    # Stylized File Content Display
    # ===================================================================
    func displayFileContent cFilename, cContent {
        nWidth = tCols() - 10
        if nWidth < 40  nWidth = 40  ok
        
        ? ""
        setColor(oTheme.getBorder())
        see "  ┌─ " 
        setColor(oTheme.getText())
        see cFilename + " "
        setColor(oTheme.getBorder())
        ? copy("─", nWidth - len(cFilename) - 1) + "┐"
        
        aLines = str2list(cContent)
        for i = 1 to len(aLines)
            setColor(oTheme.getSec())
            see "  │ "
            cNum = "" + i
            see copy(" ", 4 - len(cNum)) + cNum + " | "
            printCodeLine(aLines[i], oTheme)
        next
        
        setColor(oTheme.getBorder())
        ? "  └" + copy("─", nWidth + 6) + "┘"
        resetColor()
        ? ""
    }

    # ===================================================================
    # Display AI reasoning
    # ===================================================================
    func showThinkingContent cThought {
        if cThought = "" or cThought = null return ok
        ? ""
        setColor(oTheme.getSec())
        see "  | "
        setColor(oTheme.getPrimary())
        see oLoc.getString("reasoning") + nl
        
        aLines = str2list(cThought)
        for cLine in aLines
            setColor(oTheme.getSec())
            see "  | "
            see cLine + nl
        next
        resetColor()
    }

    # ===================================================================
    # Status bar
    # ===================================================================
    func showStatusBar cMode, nTotalTokens {
        self.nTokensUsed = nTotalTokens
        self.cLastMode = upper(cMode)
        
        nWidth = tcols()
        if nWidth < 60 nWidth = 60 ok

        cModeBadge  = " [ MODE: " + self.cLastMode + " ] "
        cTokenBadge = " [ TOKENS: " + nTotalTokens + " ] "
        cPathBadge  = " [ DIR: " + self.cCurrentDir + " ] "

        ? ""
        # 1. Draw leading separator
        setColor(DARKGREY)
        see copy("─", 2)
        
        # 2. Draw Mode Badge with dynamic Background
        switch self.cLastMode
            on "AUTO"    
                setBackgroundColor(GREEN)
                setColor(BLACK)
            on "PLAN"    
                setBackgroundColor(LIGHTBLUE)
                setColor(BLACK)
            on "EXECUTE" 
                setBackgroundColor(RED)
                setColor(WHITE)
            other        
                setBackgroundColor(MAGENTA)
                setColor(WHITE)
        off
        see cModeBadge
        resetColor()

        # 3. Draw Token Badge
        setBackgroundColor(BLACK)
        setColor(YELLOW)
        see cTokenBadge
        resetColor()

        # 4. Draw Path info (Right Aligned)
        nRemaining = nWidth - len(cModeBadge) - len(cTokenBadge) - len(cPathBadge) - 5
        setColor(DARKGREY)
        if nRemaining > 0 see copy("─", nRemaining) ok
        
        setColor(GREY)
        see cPathBadge
        resetColor()
        ? ""
    }


    # ===================================================================
    # Session separator
    # ===================================================================
    func showSeparator {
        setColor(oTheme.getSec())
        ? "  " + copy("─", 40)
        resetColor()
    }

    # ===================================================================
    # Error display
    # ===================================================================
    func showError cMsg {
        setColor(oTheme.getError())
        ? "  " + oLoc.getString("error") + cMsg
        resetColor()
    }

    # ===================================================================
    # Sensitive Action Confirmation
    # ===================================================================
    func askConfirmation cToolName, cDetails {
        ? ""
        setColor(oTheme.getText())
        see "  ╔════════════════════════════════════════════════════════════╗" + nl
        see "  ║ "
        setColor(oTheme.getError())
        see oLoc.getString("security_alert")
        setColor(oTheme.getText())
        see oLoc.getString("sensitive_action") + nl
        see "  ╠────────────────────────────────────────────────────────────╢" + nl
        see "  ║ Action: "
        setColor(oTheme.getWarn())
        see left(cToolName + copy(" ", 50), 50)
        setColor(oTheme.getText())
        see " ║" + nl
        see "  ║ Details: "
        setColor(oTheme.getSec())
        see left(cDetails + copy(" ", 49), 49)
        setColor(oTheme.getText())
        see " ║" + nl
        see "  ╚════════════════════════════════════════════════════════════╝" + nl
        ? ""
        setColor(oTheme.getPrimary())
        see "  " + oLoc.getString("auth_prompt")
        resetColor()
        
        cAction = ""
        while len(cAction) = 0
            if kbhit()
                nKey = getKey()
                if nKey = ascii("y") or nKey = ascii("Y")
                    cAction = "y"
                    see "y" + nl
                elseif nKey = ascii("n") or nKey = ascii("N")
                    cAction = "n"
                    see "n" + nl
                elseif nKey = ascii("a") or nKey = ascii("A")
                    cAction = "a"
                    see "a" + nl
                ok
            ok
        end
        if cAction = "y" return 1 ok
        if cAction = "a" return 2 ok
        return 0
    }

    # ===================================================================
    # Success notification
    # ===================================================================
    func showSuccess cMsg {
        setColor(oTheme.getAccent())
        ? "  " + oLoc.getString("success") + cMsg
        resetColor()
    }
 
    # ===================================================================
    # Help display
    # ===================================================================
    func showHelp {
        ? ""
        setColor(oTheme.getPrimary())
        ? "  Available Commands:"
        setColor(oTheme.getText())
        ? "    ls / dir / files  - List files in current directory"
        ? "    read <file>       - Read and display file contents"
        ? "    clear / cls       - Clear screen and show header"
        ? "    exit / quit       - Exit FLASH AI"
        ? ""
        setColor(oTheme.getPrimary())
        ? "  AI Capabilities (just ask naturally):"
        setColor(oTheme.getText())
        ? "    Analyze code, create files, run commands, git operations,"
        ? "    search in files, create projects, and more."
        ? ""
        resetColor()
    }

    func generateSessionId {
        return generateUniqueId()
    }

    func containsArabic cText {
        return hasArabicText(cText)
    }

    # ===================================================================
    # Inline Markdown Renderer
    # ===================================================================
    func printMarkdownLine cLine, oTheme {
        cOut = ""
        bBold = false
        bItalic = false
        bCode = false
        
        cTrim = trim(cLine)
        if left(cTrim, 2) = "# "
            cOut += char(27)+"[1m" + char(27)+"[34m"
            cLine = substr(cLine, "# ", "")
        elseif left(cTrim, 3) = "## "
            cOut += char(27)+"[1m" + char(27)+"[34m"
            cLine = substr(cLine, "## ", "")
        elseif left(cTrim, 4) = "### "
            cOut += char(27)+"[1m" + char(27)+"[34m"
            cLine = substr(cLine, "### ", "")
        elseif left(cTrim, 5) = "#### "
            cOut += char(27)+"[1m" + char(27)+"[34m"
            cLine = substr(cLine, "#### ", "")
        ok
        
        nLen = len(cLine)
        i = 1

        while i <= nLen
            c = cLine[i]
            
            if c = "*" and i < nLen and cLine[i+1] = "*"
                bBold = not bBold
                if bBold cOut += char(27)+"[1m" else cOut += char(27)+"[22m" ok
                i += 2 loop
            ok
            
            if c = "*" and i < nLen and cLine[i+1] = " "
                cOut += "•"
                i += 1 loop
            ok
            
            if c = "*"
                bItalic = not bItalic
                if bItalic cOut += char(27)+"[3m" else cOut += char(27)+"[23m" ok
                i += 1 loop
            ok
            
            if c = "`"
                bCode = not bCode
                if bCode cOut += char(27)+"[36m" else cOut += char(27)+"[39m" ok
                i += 1 loop
            ok
            
            cOut += c
            i++
        end
        cOut += char(27)+"[0m"
        see cOut + nl
    }

    # ===================================================================
    # Syntax Highlighting Engine
    # ===================================================================
    func printCodeLine cLine, oTheme {
        cLineTrim = trim(cLine)
        if left(cLineTrim, 2) = "//" or left(cLineTrim, 1) = "#" or left(cLineTrim, 2) = "/*"
            setColor(oTheme.getSec())
            ? cLine
            return
        ok
        
        bInString = false
        cQuote = ""
        cWord = ""
        aKw = ["if","else","elseif","while","for","in","to","step","return","class","func","def","switch","on","off","other","try","catch","done","true","false","null","ok","next","loop","see","print","import","from","let","var","const","function"]
        
        for i = 1 to len(cLine)
            c = cLine[i]
            if bInString
                setColor(oTheme.getWarn())
                see c
                if c = cQuote bInString = false ok
                loop
            ok
            if c = '"' or c = "'" or c = "`"
                if cWord != "" printCodeWord(cWord, aKw, oTheme) cWord = "" ok
                bInString = true
                cQuote = c
                setColor(oTheme.getWarn())
                see c
                loop
            ok
            nA = ascii(c)
            if (nA >= 48 and nA <= 57) or (nA >= 65 and nA <= 90) or (nA >= 97 and nA <= 122) or nA = 95
                cWord += c
            else
                if cWord != "" printCodeWord(cWord, aKw, oTheme) cWord = "" ok
                if c = "(" or c = ")" or c = "[" or c = "]" or c = "{" or c = "}"
                    setColor(oTheme.getBorder())
                elseif c = "=" or c = "+" or c = "-" or c = "*" or c = "/" or c = "<" or c = ">" or c = "!"
                    setColor(oTheme.getError())
                else
                    setColor(oTheme.getText())
                ok
                see c
            ok
        next
        if cWord != "" printCodeWord(cWord, aKw, oTheme) ok
        ? ""
    }
    # ===================================================================
    # Print Code Word
    # ===================================================================
    func printCodeWord cWord, aKw, oTheme {
        bNum = true
        for i = 1 to len(cWord)
            if ascii(cWord[i]) < 48 or ascii(cWord[i]) > 57
                bNum = false exit
            ok
        next
        if bNum
            setColor(oTheme.getPrimary())
            see cWord
            return
        ok
        bKey = false
        for kw in aKw
            if lower(cWord) = kw bKey = true exit ok
        next
        if bKey
            setColor(oTheme.getAccent())
        else
            setColor(WHITE)
        ok
        see cWord
    }

    # ===================================================================
    # Simplified Helper for UI Reset
    # ===================================================================
    func resetUI {
        resetColor()
        see char(27) + "[0m"
    }