# ===================================================================
# SmartAgent - Centralized Orchestration & Execution Engine
# ===================================================================
# Provides:
#   - Centralized Orchestration & Execution Engine
# ===================================================================


class SmartAgent
    
    # ===================================================================
    # Properties
    # ===================================================================
    # Core components
    oAIClient = null
    oContextEngine = null
    oAgentTools = null
    oUIManager = null
    oLogger = null
    otasktracker = null
    oSelector = null

    # Advanced subsystems (Phase 1 & Phase 3 integration)
    oSecurityLayer = null
    oTelemetry = null
    oLongTermMemory = null
    oSkillsManager = null
    oContextIntelligence = null
    oReflectionEngine = null
    oStateMachine = null
    
    # Agent configuration
    cAgentName = "FLASH AI Agent"
    cAgentVersion = "3.0"
    bDebugMode = false
    cLanguagePreference = "EN"
    
    # Current session
    cCurrentProject = ""
    cCurrentFile = ""
    cSessionId = ""
    nTotalTokens = 0
    cWorkingDirectory = currentdir()
    # Session State
    bSessionAuthorized = false
    bLanguageDetected = false
    nAgentDepth = 0
    
    # Execution Configuration
    cExecutionMode = "auto" # Values: auto, plan, execute
    bWaitingForApproval = false
    
    cActiveGoal = ""

    # ===================================================================
    # Constructor
    # ===================================================================
    func init()
        # Initialize components
        oAIClient = new AIClient()
        oContextEngine = new ContextEngine()
        oAgentTools = new AgentTools()
        oLogger = new Logger()
        nTotalTokens = 0
        oAIClient.setStreamMode(false)
        
        # Initialize advanced subsystems
        oSecurityLayer = new SecurityLayer()
        oTelemetry = new Telemetry()
        oLongTermMemory = new LongTermMemory()
        oAgentTools.oLongTermMemory = oLongTermMemory
        
        oSkillsManager = new SkillsManager()
        oAgentTools.oSkillsManager = oSkillsManager
        
        # Initialize Phase 3 Intelligence Subsystems
        oContextIntelligence = new ContextIntelligence(oContextEngine)
        oReflectionEngine = new ReflectionEngine()
        oStateMachine = new AgentStateMachine()
        oTaskTracker = new TaskTracker
        oSelector = new AdaptiveToolSelector

        # Ensure required directories exist
        ensureDirectoryExists(APP_PATH("chats"))
        ensureDirectoryExists(APP_PATH("logs"))

        # Initialize session ID using shared utility
        cSessionId = generateUniqueId()

        loadProjectGoal()

        oLogger.info("SmartAgent initialized - " + cAgentName + " v" + cAgentVersion)
    
    # ===================================================================
    # Process User Request
    # ===================================================================
    func processRequest(cUserMessage, cCurrentCode)
        //try
            # Validate input
            if cUserMessage = "" or cUserMessage = null
                return createErrorResponse("Empty message")
            ok

            # Add user message to context
            self.oContextEngine.addToHistory("user", cUserMessage, "chat")

            # Learn from dialogue
            if oLongTermMemory != null
                oLongTermMemory.learnFromDialogue("user", cUserMessage)
            ok

            # Determine request type
            cRequestType = analyzeRequestType(cUserMessage)
            
            # Auto-detect language continuously for Arabic input
            if isfunction("hasArabicText") and hasArabicText(cUserMessage)
                setLanguage("AR")
            elseif not bLanguageDetected
                if substr(cUserMessage, "عربي") or substr(cUserMessage, "عربية") or substr(cUserMessage, "اريد") or substr(cUserMessage, "مرحبا") or substr(cUserMessage, "السلام")
                    setLanguage("AR")
                else
                    setLanguage("EN")
                ok
            ok
            bLanguageDetected = true

            # Check if this is a tool request
            oToolRequest = parseToolRequest(cUserMessage)

            if oToolRequest["is_tool_request"]
                # Execute tool directly
                return executeToolRequest(oToolRequest, cCurrentCode)
            else
                # Send to AI for processing
                return sendToAI(cUserMessage, cRequestType, cCurrentCode)
            ok

       /* catch
            return createErrorResponse("Request processing failed: " + cCatchError)
        done*/

    # ===================================================================
    # Advanced Request Type Analyzer (Context-Aware Intent Detection)
    # ===================================================================
    func analyzeRequestType(cMessage)
        cMsg = lower(trim(cMessage))
        
        # 1. Self-Evolution Intent (Highest Priority)
        # Keywords: evolve, build tool, create tool, مهارة جديدة, طور أداة
        if hasKeywords(cMsg, ["evolve", "new tool", "build tool", "create tool", "طور", "أداة", "مهارة"])
            return "self_evolution"
        ok

        # 2. Project & Git Operations
        # Keywords: project, scaffold, init, git, commit, push, مشروع, هيكل, مستودع
        if hasKeywords(cMsg, ["project", "scaffold", "init", "git", "commit", "push", "status", "مشروع", "هيكل", "مستودع", "رفع"])
            return "project_management"
        ok

        # 3. Code Analysis & Execution
        # Keywords: analyze, debug, review, format, run, test, حلل, افحص, راجع, شغل
        if hasKeywords(cMsg, ["analyze", "debug", "review", "format", "run", "test", "fix", "حلل", "افحص", "راجع", "صلح", "شغل", "اختبار"])
            return "code_analysis"
        ok

        # 4. File Operations
        # Keywords: write, read, delete, create file, edit, save, اكتب, اقرأ, احذف, عدل
        if hasKeywords(cMsg, ["write", "read", "delete", "create file", "edit", "save", "mkdir", "اكتب", "اقرأ", "احذف", "انشئ", "عدل", "حفظ"])
            return "file_operation"
        ok

        # 5. Web & Data Operations
        # Keywords: url, download, fetch, bitcoin, ويب, رابط, تحميل
        if hasKeywords(cMsg, ["url", "download", "fetch", "http", "website", "bitcoin", "رابط", "موقع", "ويب", "تحميل"])
            return "web_operation"
        ok

        # 6. System & Shell Operations
        # Keywords: execute, terminal, shell, cmd, نفذ, أمر, تيرمينال
        if hasKeywords(cMsg, ["execute", "terminal", "shell", "cmd", "command", "system", "نفذ", "أمر", "نظام"])
            return "system_operation"
        ok

        # Default: General Chat (Minimal tools will be sent)
        return "general_chat"

    # --- Helper function for keyword matching ---
    func hasKeywords(cMsg, aKeywords)
        for word in aKeywords
            if substr(cMsg, word) > 0
                return true
            ok
        next
        return false

    # ===================================================================
    # Parse Tool Request
    # ===================================================================
    func parseToolRequest(cMessage)
        oResult = [
            "is_tool_request" = false,
            "tool_name" = "",
            "parameters" = []
        ]
        
        # We rely on main.ring for explicit local commands (read, list, clear).
        # Normal conversation should always go to the AI.
        
        return oResult
    
    # ===================================================================
    # Execute Tool Request
    # ===================================================================
    func executeToolRequest(oToolRequest, cCurrentCode)
        try
            cToolName = oToolRequest["tool_name"]
            aParameters = oToolRequest["parameters"]
            
            # Add current code as parameter if needed
            if cToolName = "run_ring_code" and len(aParameters) = 0
                aParameters = [cCurrentCode]
            ok
            
            # Validate parameters
            aValidation = oAgentTools.validateToolParameters(cToolName, aParameters)
            if not aValidation[1]
                return createErrorResponse("Tool validation failed: " + aValidation[2])
            ok
            
            # Execute tool
            oResult = oAgentTools.executeTool(cToolName, aParameters)
            
            # Add result to context
            cResultMessage = ""
            if oResult["success"]
                cResultMessage = "Tool executed successfully: " + oResult["message"]
                self.oContextEngine.addFileContext(cToolName, "direct_execution", "success")
            else
                cResultMessage = "Tool execution failed: " + oResult["error"]
                self.oContextEngine.addFileContext(cToolName, "direct_execution", "error")
            ok
            
            self.oContextEngine.addToHistory("assistant", cResultMessage, "tool_result")
            
            return createSuccessResponse(cResultMessage)
            
        catch
            return createErrorResponse("Tool execution error: " + cCatchError)
        done

    # ===================================================================
    # Send to AI — Refactored with Formal State Machine
    # ===================================================================
    func sendToAI(cMessage, cRequestType, cCurrentCode)
       // try
            oContextMap = prepareContextMap(cMessage, cRequestType, cCurrentCode)
            aConversation = buildInitialConversation(oContextMap)
            
            nMaxIterations = 25
            nIteration = 0
            aToolsUsed = []
            nRequestTokens = 0  # Per-request token counter (reset each request)
            nConsecFails = 0    # Consecutive tool failures (bounded by ReflectionEngine.nMaxRetries)
            cLastToolSig = ""
            nDuplicateToolCalls = 0
            
            if oStateMachine != null oStateMachine.transition(AGENT_CALLING_LLM) ok

            while nIteration < nMaxIterations
                nIteration++

                if oUIManager != null try oUIManager.processEvents() catch done ok
                
                # Update FSM state logically (Phase 4.1 Refined)
                if nIteration = 1
                    if cExecutionMode = "plan"
                        if oStateMachine != null oStateMachine.transition(AGENT_PLANNING) ok
                    else
                        if oStateMachine != null oStateMachine.transition(AGENT_CALLING_LLM) ok
                    ok
                else
                    # Maintain Planning state if we are still exploring
                    if cExecutionMode = "plan" and oStateMachine.nCurrentState = AGENT_PLANNING
                        # Stay in planning
                    else
                        if oStateMachine != null oStateMachine.transition(AGENT_CALLING_LLM) ok
                    ok
                ok

                # Rebuild context array dynamically to include new user messages, tool calls, and results
                if nIteration > 1 and len(self.oContextEngine.aFileContext) > 0
                    oContextMap = prepareContextMap(cMessage, cRequestType, cCurrentCode)
                ok
                oContextMap[:context_array] = self.oContextIntelligence.buildWeightedContext(cRequestType, cCurrentCode, 15000)
                if nIteration = 1
                    aConversation = buildInitialConversation(oContextMap)
                ok

                oAIResponse = dispatchToProvider(oContextMap, aConversation, cMessage)
                
                if not oAIResponse[:success]
                    if oStateMachine != null oStateMachine.transition(AGENT_ERROR) ok
                    return createErrorResponse("AI request failed: " + oAIResponse[:error])
                ok
                
                nRequestTokens = updateCurrentTokenCount(oAIResponse, nRequestTokens)
                displayAgentThoughtAndMessage(oAIResponse)
                
                # [ CRITICAL FIX ] Immediate Goal & Roadmap Detection 
                # We do this inside the loop so we don't lose the goal if the agent gets stuck in tool calls
                detectAndRecordIntent(oAIResponse, nIteration)

                cResponseType = getValueFromList(oAIResponse, "type", "text")
                
                # Logic for /plan mode: Allow READ-ONLY tools, but Pause on WRITE tools
                if cExecutionMode = "plan"
                    if cResponseType = "function_call"
                        if hasWritingToolCall(oAIResponse)
                            # AI wants to modify something or use mixed tools - CATEGORICAL STOP
                            if oStateMachine != null oStateMachine.transition(AGENT_AWAITING_APPROVAL) ok
                            bWaitingForApproval = true
                            oFinalRes = finalizeAgentResponse(oAIResponse, aToolsUsed, oContextMap, nIteration, nRequestTokens)
                            oFinalRes[:message] += nl + nl + "🛡️ [ PROTOCOL STOP ] The agent has a plan but attempted writing tool(s)." + nl + "Use /execute to authorize the transition or /auto to proceed."
                            return oFinalRes
                        ok
                        # If it IS purely read-only tools, let the loop continue
                    else
                        # No tool call, just final analysis/plan
                        if oStateMachine != null oStateMachine.transition(AGENT_AWAITING_APPROVAL) ok
                        bWaitingForApproval = true
                        oFinalRes = finalizeAgentResponse(oAIResponse, aToolsUsed, oContextMap, nIteration, nRequestTokens)
                        oFinalRes[:message] += nl + nl + "🏁 [ PLAN COMPLETE ] Review the analysis above. Use /execute to proceed with implementation."
                        return oFinalRes
                    ok
                ok

                if cResponseType = "function_call"
                    # --- Repetitive Tool Call Guard (Anti-Loop Protection) ---
                    cCurrentToolName = lower(trim(oAIResponse[:function_name]))
                    cCurrentToolSig = cCurrentToolName + ":" + list2json(oAIResponse[:function_args])
                    if cCurrentToolSig = cLastToolSig
                        nDuplicateToolCalls++
                    else
                        cLastToolSig = cCurrentToolSig
                        nDuplicateToolCalls = 0
                    ok

                    if nDuplicateToolCalls >= 1
                        if oUIManager != null 
                            oUIManager.displaySystemNote("Loop detected: Duplicate execution of '" + cCurrentToolName + "' prevented.")
                        ok
                        oToolResult = createErrorResult("[LOOP PREVENTION] You have ALREADY executed '" + cCurrentToolName + "' with identical parameters in the previous turn. The results are already available in your conversation history above. DO NOT re-execute the same tool with the same arguments. Proceed directly to read specific files (read_file), analyze what you found, or reply to the user.")
                        aConversation = appendToolResultToConversation(aConversation, oAIResponse, oToolResult)
                        cMessage = ""
                        loop
                    ok

                    # Final Guard: Ensure we don't jump from Planning to Execution without the user's "green light"
                    if oStateMachine != null and oStateMachine.nCurrentState = AGENT_PLANNING
                       if hasWritingToolCall(oAIResponse)
                           oStateMachine.transition(AGENT_AWAITING_APPROVAL)
                           return createErrorResponse("Protocol Violation: Attempted to execute writing tools while in Planning state.")
                       ok
                    ok

                    if oStateMachine != null oStateMachine.transition(AGENT_EXEC_TOOL) ok
                    
                    oToolResult = executeToolSafely(oAIResponse, aToolsUsed)
                    
                    if not oToolResult[:success]
                        if oStateMachine != null oStateMachine.transition(AGENT_REFLECTING) ok
                        nConsecFails++
                        # Resilient self-healing loop: allow the agent sufficient turns
                        # to inspect compiler output, adjust code, and verify fixes.
                        nMaxFails = 6
                        if oReflectionEngine != null nMaxFails = oReflectionEngine.nMaxRetries ok
                        if nConsecFails > nMaxFails
                            if oUIManager != null oUIManager.displaySystemNote("Stopping after " + nConsecFails + " consecutive tool failures. Review the error and adjust your approach.") ok
                            oFinalRes = finalizeAgentResponse(oAIResponse, aToolsUsed, oContextMap, nIteration, nRequestTokens)
                            oFinalRes[:message] = oToolResult[:error] + nl + nl + "[ FLASH_AI ] Aborted after repeated tool failures. Please review the diagnosis above and try a different approach."
                            return oFinalRes
                        ok
                    else
                        if oStateMachine != null oStateMachine.transition(AGENT_CALLING_LLM) ok
                        nConsecFails = 0
                    ok
                    
                    aConversation = appendToolResultToConversation(aConversation, oAIResponse, oToolResult)
                    cMessage = "" # Clear message for loop
                    loop
                ok
                
                if oStateMachine != null oStateMachine.transition(AGENT_FINALIZING) ok
                return finalizeAgentResponse(oAIResponse, aToolsUsed, oContextMap, nIteration, nRequestTokens)
            end
            
            # Fallback response if loop exits without explicit final response
            oFinal = finalizeAgentResponse(oAIResponse, aToolsUsed, oContextMap, nIteration, nRequestTokens)
            if oFinal[:message] = ""
                oFinal[:message] = "[ FLASH_AI ] Tools executed successfully."
            ok
            return oFinal

       /* catch
            if oStateMachine != null oStateMachine.transition(AGENT_ERROR) ok
            return createErrorResponse("AI request execution error: " + cCatchError)
        done*/

    # ===================================================================
    # Phase 4 Decomposed Helpers for sendToAI
    # ===================================================================

    func prepareContextMap(cMessage, cRequestType, cCurrentCode)
        nContextBudget = 15000
        aContext = self.oContextIntelligence.buildWeightedContext(cRequestType, cCurrentCode, nContextBudget)
        
        # Mode Injection Architecture (Phase 4.1 Update)
        cModeInstruction = ""
        switch cExecutionMode
            on "plan"
                cModeInstruction = " [ STATUS: PLANNING MODE ] " + nl + 
                                   "🚨 IMPORTANT PROTOCOL: You are in READ-ONLY mode. " + nl + 
                                   "1. You MAY use exploration tools (list_files, read_file, grep_search, analyze_project, git_status, analyze_code) to understand the codebase." + nl + 
                                   "2. DO NOT call any modification tools (write, replace, delete, execute_command, git_commit, evolve_new_tool)." + nl + 
                                   "3. First, provide a high-level summary of your plan." + nl + 
                                   "4. Once you have a complete plan, stop and wait for approval. USE TERMINATING MESSAGE ONLY." + nl
            on "execute"
                cModeInstruction = " [ STATUS: EXECUTION MODE ] IMPORTANT: Skip conversational preamble. Proceed directly to tool execution and complete the task as requested." + nl
            on "auto"
                cModeInstruction = " [ STATUS: AUTONOMOUS MODE ] You are free to plan and execute tools iteratively as needed." + nl
        off
        
        # Resource Awareness Injection (Token Quota)
        nLimit = 1000000
        nPercent = 100.0 - ((self.nTotalTokens / nLimit) * 100.0)
        if nPercent < 0 nPercent = 0 ok
        cQuotaInfo = " [ RESOURCE STATUS: " + nPercent + "% Quota Remaining ] " + nl +
                     "🚨 ADVICE: You are using a free tier API. Manage your tool calls and context length wisely to avoid being throttled or blocked." + nl

        cSystemPrompt = cQuotaInfo + cModeInstruction + self.oContextEngine.getSystemPrompt(cRequestType)

        # Persistence: Injection of current goal into system prompt
        if self.cActiveGoal != ""
            cSystemPrompt = "🎯 [ PRIMARY OBJECTIVE: " + self.cActiveGoal + " ] " + nl + cSystemPrompt
        ok

        if cCurrentCode != "" and cCurrentCode != null
            self.oContextEngine.addCodeContext(self.cCurrentFile, cCurrentCode, "ring")
        ok

        cMemoryContext = ""
        if oLongTermMemory != null
            # Build a richer recall context: combine the current message with a
            # short summary of the recent conversation so cross-turn memory is
            # actually surfaced to the model (previously only cMessage was used).
            cRecallQuery = cMessage
            aRecent = self.oContextEngine.aConversationHistory
            nRecentStart = max(1, len(aRecent) - 6)
            for i = nRecentStart to len(aRecent)
                cRecallQuery = cRecallQuery + " " + getValueFromList(aRecent[i], "content", "")
            next
            cMemoryContext = oLongTermMemory.buildContextInjection(cRecallQuery, 1200)
        ok

        # Session-Aware Context: tell the model what it already explored THIS
        # session so it stops re-listing / re-reading the same paths (the core
        # "doesn't remember between turns / re-uses tools" complaint).
        # Built primarily from aConversationHistory tool results (authoritative),
        # with aFileContext/aCodeContext as a secondary index.
        cSessionKnowledge = ""
        aExploredDirs = []
        aReadFiles = []
        aModified = []
        aHist = self.oContextEngine.aConversationHistory
        for i = max(1, len(aHist) - 20) to len(aHist)
            oMsg = aHist[i]
            if getValueFromList(oMsg, "type", "") = "tool_result"
                cContent = getValueFromList(oMsg, "content", "")
                if substr(cContent, "Files in ")
                    # Extract the directory from "Files in X:"
                    nPos = substr(cContent, "Files in ")
                    cRest = substr(cContent, nPos + len("Files in "))
                    cDir = split(cRest, ":")[1]
                    cDir = trim(split(cDir, nl)[1])
                    if cDir != "" and find(aExploredDirs, cDir) = 0 aExploredDirs + cDir ok
                ok
                if substr(cContent, "File content:") or substr(cContent, "File content:")
                    # Find the read_file call that produced this in the prior turn
                    if i > 1
                        oPrev = aHist[i - 1]
                        if getValueFromList(oPrev, "type", "") = "tool_call"
                            cPrev = getValueFromList(oPrev, "content", "")
                            nPos = substr(cPrev, "READ_FILE")  # may be uppercase in display
                            if nPos = 0 nPos = substr(lower(cPrev), "read_file") ok
                            if nPos > 0
                                cRest = substr(cPrev, nPos)
                                cFn = trim(split(cRest, nl)[1])
                                # strip "READ_FILE  → filename: " prefix
                                nFn = substr(cFn, "filename:")
                                if nFn > 0 cFn = trim(substr(cFn, nFn + len("filename:"))) ok
                                if cFn != "" and find(aReadFiles, cFn) = 0 aReadFiles + cFn ok
                            ok
                        ok
                    ok
                ok
            ok
        next
        # Also fold in the file/code context index (catches execute_command etc.)
        for oFC in self.oContextEngine.aFileContext
            cFn = getValueFromList(oFC, "filename", "")
            cOp = getValueFromList(oFC, "operation", "")
            if cFn != "" and cOp = "explored" and find(aExploredDirs, cFn) = 0 aExploredDirs + cFn ok
            if cFn != "" and cOp = "modified" and find(aModified, cFn) = 0 aModified + cFn ok
        next
        for oCC in self.oContextEngine.aCodeContext
            cFn = getValueFromList(oCC, "filename", "")
            if cFn != "" and find(aReadFiles, cFn) = 0 aReadFiles + cFn ok
        next

        if len(aExploredDirs) > 0 or len(aReadFiles) > 0 or len(aModified) > 0
            cSessionKnowledge = "[SESSION KNOWLEDGE — you ALREADY explored/fetched this, REUSE it instead of re-listing or re-reading the same path]" + nl
            if len(aExploredDirs) > 0
                cSessionKnowledge += "• Directories already listed/explored: " + list2str(aExploredDirs) + nl
            ok
            if len(aReadFiles) > 0
                cSessionKnowledge += "• Files already read: " + list2str(aReadFiles) + nl
            ok
            if len(aModified) > 0
                cSessionKnowledge += "• Files already modified: " + list2str(aModified) + nl
            ok
        ok
        if cSessionKnowledge != ""
            cSystemPrompt = cSystemPrompt + nl + nl + cSessionKnowledge
        ok

        # Inject Skills Catalog (Markdown-based Progressive Disclosure)
        cSkillsCatalog = ""
        if oSkillsManager != null
            cSkillsCatalog = oSkillsManager.getSkillsCatalogPrompt()
        ok
        if cSkillsCatalog != ""
            cSystemPrompt = cSystemPrompt + nl + nl + cSkillsCatalog
        ok

        cFullPrompt = buildContextualPrompt(cMessage, cSystemPrompt, aContext)
        if cMemoryContext != ""
            cFullPrompt = cMemoryContext + nl + cFullPrompt
        ok

        nLoopStartClock = 0
        if oTelemetry != null nLoopStartClock = oTelemetry.startAPITimer() ok


        cActiveTask = self.oTaskTracker.getNextTask()
        cRoadmapNote = ""
        
        if cActiveTask != ""
            # Force the agent to know that it is in the middle of a task
            cRoadmapNote = "---" + nl +
                        "📋 [SYSTEM NOTIFICATION - ACTIVE TASK]" + nl +
                        "You are currently executing this specific step: " + cActiveTask + nl +
                        "If the user says 'اكمل' or 'continue', proceed with this task immediately." + nl +
                        "---" + nl
        ok

        if cRoadmapNote != ""
            cSystemPrompt = cRoadmapNote + cSystemPrompt
        ok
        

        return [
            :request_type = cRequestType,
            :full_prompt = cFullPrompt,
            :system_prompt = cSystemPrompt,
            :loop_start = nLoopStartClock,
            :context_array = aContext,
            :memory_context = cMemoryContext,
            :user_message = cMessage
        ]

    func buildInitialConversation(oContextMap)
        cLangHint = "Response Language: " + upper(cLanguagePreference)
        aConversation = []
        
        # System Message as first turn
        cSys = ""
        if oContextMap[:system_prompt] != "" cSys += "System: " + oContextMap[:system_prompt] + nl + nl ok
        if oContextMap[:memory_context] != "" cSys += oContextMap[:memory_context] + nl + nl ok
        
        if cSys != ""
            Add(aConversation, [ ["role", "user"], ["parts", [ [["text", cSys]] ] ] ])
            Add(aConversation, [ ["role", "model"], ["parts", [ [["text", "Understood. I will follow the instructions."]] ] ] ])
        ok
        
        # Add past context array
        aContext = oContextMap[:context_array]
        nEndLimit = 0
        if type(aContext) = "LIST"
            nEndLimit = len(aContext)
            if nEndLimit > 0
                oLastCtx = aContext[nEndLimit]
                if type(oLastCtx) = "LIST"
                    cLastRole = self.oAIClient.getValue(oLastCtx, "role", "")
                    cLastContent = self.oAIClient.getValue(oLastCtx, "content", "")
                    if cLastRole = "user" and (cLastContent = oContextMap[:user_message] or oContextMap[:user_message] = "")
                        nEndLimit--
                    ok
                ok
            ok
        ok
        
        if type(aContext) = "LIST" and nEndLimit > 0
            for i = 1 to nEndLimit
                oItem = aContext[i]
                if type(oItem) != "LIST" loop ok
                cRole = self.oAIClient.getValue(oItem, "role", "user")
                cContent = self.oAIClient.getValue(oItem, "content", "")
                cToolCallID = self.oAIClient.getValue(oItem, "tool_call_id", "")
                aToolCalls = self.oAIClient.getValue(oItem, "tool_calls", [])
                
                if cRole = "tool"
                    cName = self.oAIClient.getValue(oItem, "name", cToolCallID)
                    aFuncRes = [
                        ["role", "user"],
                        ["parts", [
                            [["functionResponse", [
                                ["name", cName],
                                ["response", [
                                    ["name", cName],
                                    ["content", cContent]
                                ]]
                            ]]]
                        ]]
                    ]
                    Add(aConversation, aFuncRes)
                elseif cRole = "assistant" and len(aToolCalls) > 0
                    aParts = []
                    if cContent != "" aParts + [["text", cContent]] ok
                    for aCall in aToolCalls
                        if type(aCall) = "LIST"
                            oFunc = self.oAIClient.getValue(aCall, "function", [])
                            cName = self.oAIClient.getValue(oFunc, "name", "")
                            vArgs = self.oAIClient.getValue(oFunc, "arguments", "{}")
                            oParsedArgs = []
                            if type(vArgs) = "LIST"
                                oParsedArgs = vArgs
                            elseif type(vArgs) = "STRING" and vArgs != ""
                                try oParsedArgs = json2list(vArgs) catch done
                            ok
                            if type(oParsedArgs) = "LIST" and len(oParsedArgs) = 0
                                oParsedArgs = [ [":_is_object", true] ]
                            ok
                            aParts + [ ["functionCall", [ ["name", cName], ["args", oParsedArgs] ]] ]
                        ok
                    next
                    Add(aConversation, [ ["role", "model"], ["parts", aParts] ])
                else
                    cMappedRole = cRole
                    if cMappedRole = "assistant" cMappedRole = "model" ok
                    if cMappedRole = "system" cMappedRole = "user" ok
                    if cContent != ""
                        Add(aConversation, [ ["role", cMappedRole], ["parts", [ [["text", cContent]] ] ] ])
                    ok
                ok
            next
        ok
        
        # Add the current user message ONLY IF the conversation does not end with a function turn
        # AND it wasn't already added as the last user turn.
        bLastIsFunction = false
        if len(aConversation) > 0
            oLastTurn = aConversation[len(aConversation)]
            if type(oLastTurn) = "LIST" and len(oLastTurn) >= 1
                cLastTurnRole = oLastTurn[1][2]
                if cLastTurnRole = "function" or cLastTurnRole = "tool"
                    bLastIsFunction = true
                ok
            ok
        ok

        if not bLastIsFunction and oContextMap[:user_message] != ""
            bAlreadyInConversation = false
            if len(aConversation) > 0
                oLastTurn = aConversation[len(aConversation)]
                if type(oLastTurn) = "LIST" and len(oLastTurn) >= 2 and oLastTurn[1][2] = "user"
                    aParts = oLastTurn[2][2]
                    if type(aParts) = "LIST" and len(aParts) > 0
                        cTxt = self.oAIClient.getValue(aParts[1], "text", "")
                        if substr(cTxt, oContextMap[:user_message]) > 0
                            bAlreadyInConversation = true
                        ok
                    ok
                ok
            ok
            if not bAlreadyInConversation
                cUsrMsg = cLangHint + nl + oContextMap[:user_message]
                Add(aConversation, [ ["role", "user"], ["parts", [ [["text", cUsrMsg]] ] ] ])
            ok
        ok
        
        # ============================================================
        # CRITICAL: Enforce strict role alternation for Gemini API
        # Gemini requires user→model→user→model turns. Consecutive
        # same-role turns cause the API to ignore earlier context.
        # Merge consecutive same-role turns by combining their parts.
        # ============================================================
        aFinal = []
        for i = 1 to len(aConversation)
            oTurn = aConversation[i]
            if type(oTurn) != "LIST" or len(oTurn) < 2
                Add(aFinal, oTurn)
                loop
            ok
            cRole = oTurn[1][2]
            
            if len(aFinal) > 0
                cPrevRole = aFinal[len(aFinal)][1][2]
                if cRole = cPrevRole and cRole != "function"
                    # Merge: append this turn's parts into the previous turn
                    aPrevParts = aFinal[len(aFinal)][2][2]
                    aNewParts = oTurn[2][2]
                    for oPart in aNewParts
                        Add(aPrevParts, oPart)
                    next
                    loop  # Skip adding as separate turn
                ok
            ok
            Add(aFinal, oTurn)
        next
        
        return aFinal
        
    # ===================================================================
    # Dispatch to Provider
    # ===================================================================
    func dispatchToProvider(oContextMap, aConversation, cMessage)
       
        # Get relevant tools based on the current request type
        cType = oContextMap[:request_type] # Ensure this is passed in the map
        aRelevant = self.oSelector.getRelevantTools(cType)
        
        if self.oAIClient.cCurrentProvider = "openrouter"
            # Send only the relevant subset to OpenRouter
            cToolsJSON = self.oAgentTools.getFilteredOpenAIJSON(aRelevant)
            return self.oAIClient.sendOpenRouterRequest(cMessage, oContextMap[:system_prompt], oContextMap[:context_array], cToolsJSON)
            
        elseif self.oAIClient.cCurrentProvider = "deepseek"
            # Send only the relevant subset to DeepSeek
            cToolsJSON = self.oAgentTools.getFilteredOpenAIJSON(aRelevant)
            return self.oAIClient.sendDeepSeekRequest(cMessage, oContextMap[:system_prompt], oContextMap[:context_array], cToolsJSON)
            
        elseif self.oAIClient.cCurrentProvider = "nvidia"
            # Send only the relevant subset to Nvidia
            cToolsJSON = self.oAgentTools.getFilteredOpenAIJSON(aRelevant)
            return self.oAIClient.sendNvidiaRequest(cMessage, oContextMap[:system_prompt], oContextMap[:context_array], cToolsJSON)
            
        elseif self.oAIClient.cCurrentProvider = "gemini"
            # Send only the relevant subset to Gemini
            cToolsJSON = self.oAgentTools.getFilteredGeminiJSON(aRelevant)
            cConvertJSON = jsonEncode(aConversation)
            
            if self.oAIClient.bStreamMode
                return self.oAIClient.sendGeminiStreaming(cConvertJSON, cToolsJSON)
            else
                return self.oAIClient.sendGeminiConversation(cConvertJSON, cToolsJSON)
            ok
        else
            return self.oAIClient.sendChatRequest(cMessage, oContextMap[:system_prompt], oContextMap[:context_array])
        ok

    func updateCurrentTokenCount(oAIResponse, nRequestTokens)
        nBatchTokens = oAIResponse[:total_tokens]
        if nBatchTokens = NULL or type(nBatchTokens) != "NUMBER" 
            nBatchTokens = 0 
        ok
        nRequestTokens += nBatchTokens
        self.nTotalTokens += nBatchTokens
        self.oAIClient.addTokens(nBatchTokens)
        return nRequestTokens

    func displayAgentThoughtAndMessage(oAIResponse)
        cThoughtContent = oAIResponse[:thought]
        if cThoughtContent != "" and cThoughtContent != null
            if oUIManager != null 
                oUIManager.showThinkingContent(cThoughtContent)
            else
                ? "[ REASONING ] " + cThoughtContent
            ok
        ok

        cMsgContent = oAIResponse[:message]
        if cMsgContent != "" and cMsgContent != null
            # If streaming was active, the message has already been printed chunk by chunk
            if self.oAIClient.bStreamMode
                ? "" # Final new line
                return
            ok
            
            if oUIManager != null 
                oUIManager.displayAIMessage(cMsgContent)
            else
                ? "[ FLASH ] " + cMsgContent
            ok
        ok

    func executeToolSafely(oAIResponse, aToolsUsed)
        cToolName = trim(oAIResponse[:function_name])
        oToolArgs = oAIResponse[:function_args]

        if substr(cToolName, ":")
            pos = substr(cToolName, ":")
            cToolName = substr(cToolName, pos + 1)
        ok
        cToolName = lower(trim(cToolName))

        if find(aToolsUsed, cToolName) = 0
            aToolsUsed + cToolName
        ok

        aParams = extractToolParams(cToolName, oToolArgs)
        cDetails = ""
        bCanExecute = true
        for p in aParams
            if type(p) = "LIST" and len(p) >= 2
                cVal = p[2]
                if islist(cVal) cVal = "[List]" ok
                cDetails += "" + p[1] + ": " + self.oContextEngine.truncateLongText("" + cVal, 100) + " | "
            ok
        next

        if oUIManager != null 
            oUIManager.displayToolAction(cToolName, cDetails)
        else
            if isfunction("setcolor")
                setColor(YELLOW)
                ? "  [ FLASH ] " + cToolName + " (" + cDetails + ")"
                resetColor()
            else
                ? "  [ FLASH ] " + cToolName + " (" + cDetails + ")"
            ok
        ok

        # --- Step 1: User Confirmation (must come BEFORE SecurityLayer) ---
        bUserApprovedThisTool = false

        # Check if operation is scoped within project directory
        bWithinProject = false
        if isPathTool(cToolName)
            cPth = ""
            if len(aParams) > 0
                if cToolName = "grep_search" or cToolName = "search_in_files"
                    if len(aParams) >= 2 cPth = aParams[2] ok
                else
                    cPth = aParams[1]
                ok
                if type(cPth) = "LIST" and len(cPth) >= 2 cPth = cPth[2] ok
            ok
            if type(cPth) = "STRING"
                if cPth = "" or (isPathSafeCheck(cPth) and not self.oAgentTools.isCoreProtected(cPth))
                    bWithinProject = true
                ok
            ok
        elseif substr(lower(cToolName), "skill") or substr(lower(cToolName), "memory")
            bWithinProject = true
        ok

        # Auto-approve actions operating safely within project directory
        if bWithinProject
            bUserApprovedThisTool = true
        ok

        if bCanExecute and isSensitiveToolCheck(cToolName) and not bWithinProject
            if not bSessionAuthorized
                nAuthRes = 1  # Default: allow (overridden below)
                if oUIManager != null
                    nAuthRes = oUIManager.askConfirmation(cToolName, cDetails)
                else
                    # CLI Fallback — prompt user directly in terminal
                    see nl + "⚠️  [SECURITY] Sensitive tool: " + cToolName + nl
                    see "   Details: " + cDetails + nl
                    see "   Type 'yes' to approve, 'always' for session-wide, or anything else to deny: "
                    give cAuthInput
                    cAuthInput = trim(lower(cAuthInput))
                    if cAuthInput = "yes" or cAuthInput = "y"
                        nAuthRes = 1
                    elseif cAuthInput = "always" or cAuthInput = "all"
                        nAuthRes = 2
                    else
                        nAuthRes = 0
                    ok
                ok
                if nAuthRes = 0
                    bCanExecute = false
                    return [:success = false, :error = "CANCELLED: The user denied permission.", :message = ""]
                elseif nAuthRes = 2
                    setSessionAuthorized(true)
                elseif nAuthRes = 1
                    bUserApprovedThisTool = true
                ok
            ok
        ok

        # --- Step 2: SecurityLayer Validation (skipped if user just approved) ---
        if bCanExecute and oSecurityLayer != null and not bUserApprovedThisTool
            aSecCheck = oSecurityLayer.validateToolExecution(cToolName, aParams)
            if not aSecCheck[1]
                bCanExecute = false
                return [:success = false, :error = aSecCheck[2], :message = ""]
            ok
        ok

        # --- Step 3: Path Safety Validation ---
        if bCanExecute and isPathTool(cToolName)
            aPathIndices = [1]
            if cToolName = "grep_search" or cToolName = "search_in_files" aPathIndices = [2] ok
            for nIdx in aPathIndices
                if nIdx <= len(aParams)
                    cPth = aParams[nIdx]
                    if type(cPth) = "LIST" cPth = cPth[2] ok
                    if type(cPth) = "STRING" and cPth != "" and not bSessionAuthorized and not isPathSafeCheck(cPth)
                        bCanExecute = false
                        return [:success = false, :error = "SECURITY ERROR: Unauthorized path access: " + cPth, :message = ""]
                    ok
                ok
            next
        ok

        if bCanExecute
            nToolStartClock = 0
            if oTelemetry != null nToolStartClock = oTelemetry.startToolTimer() ok
            
            oToolResult = self.oAgentTools.executeTool(cToolName, aParams)

            # Defensive Check: ensure oToolResult is ALWAYS a valid List
            if type(oToolResult) != "LIST"
                if type(oToolResult) = "STRING" and oToolResult != ""
                    oToolResult = createSuccessResult(oToolResult)
                else
                    oToolResult = createErrorResult("Tool execution returned non-list format: " + string(oToolResult))
                ok
            ok
            if oToolResult[:success] = null
                oToolResult[:success] = false
            ok
            if oToolResult[:message] = null
                oToolResult[:message] = ""
            ok
            if oToolResult[:error] = null
                oToolResult[:error] = ""
            ok

            if oTelemetry != null oTelemetry.recordToolExecution(cToolName, nToolStartClock, oToolResult[:success]) ok
            cLearnMsg = oToolResult[:message]
            if not oToolResult[:success]
                cLearnMsg = oToolResult[:error]
            ok
            if oLongTermMemory != null oLongTermMemory.learnFromToolResult(cToolName, aParams, oToolResult[:success], "" + cLearnMsg) ok

            if oToolResult[:success]
                cResultText = "" + oToolResult[:message]
                if oUIManager != null
                    try
                        oUIManager.displayToolOutput(cResultText)
                    catch
                        see "  │   └─ " + left(cResultText, 100) + nl
                    done
                else
                    see "  │   └─ " + left(cResultText, 100) + nl
                ok
                cResultText = self.oContextEngine.truncateLongText(cResultText, 4000)
                
                if oToolResult[:added] != null and (oToolResult[:added] > 0 or oToolResult[:removed] > 0)
                    cFirstParamVal = ""
                    if len(aParams) >= 1
                        if type(aParams[1]) = "LIST" and len(aParams[1]) >= 2
                            cFirstParamVal = "" + aParams[1][2]
                        else
                            cFirstParamVal = "" + aParams[1]
                        ok
                    ok
                    if oUIManager != null
                        try
                            oUIManager.displayToolStats(cFirstParamVal, oToolResult[:added], oToolResult[:removed])
                        catch
                            see "   [STATS] " + cFirstParamVal + " | +" + oToolResult[:added] + " / -" + oToolResult[:removed] + nl
                        done
                    else
                        see "   [STATS] " + cFirstParamVal + " | +" + oToolResult[:added] + " / -" + oToolResult[:removed] + nl
                    ok
                ok
                return [:success = true, :message = cResultText, :error = "", :tool_name = cToolName, :params = aParams]
            else
                cResultText = "Error: " + oToolResult[:error]
                if cResultText = "Error: " or cResultText = "Error: null"
                    cResultText = "Error: Tool failed without providing a detailed error message."
                ok
                if oReflectionEngine != null
                    oDiagnosis = oReflectionEngine.analyzeFailure(cToolName, cResultText, aParams)
                    cRecovery = oReflectionEngine.buildRecoveryPrompt(oDiagnosis)
                    if oReflectionEngine.shouldRetry(oDiagnosis)
                        if oUIManager != null
                            cSysNote = "Self-Correction Triggered: " + getValueFromList(oDiagnosis, "diagnosis", "")
                            oUIManager.displaySystemNote(cSysNote)
                        ok
                        # IMPORTANT: propagate the recovery guidance so the model
                        # actually sees the corrected approach on the next loop turn.
                        cResultText = cResultText + nl + nl + cRecovery
                    else
                        # Even when a retry is not recommended (e.g. repeat failure),
                        # surface the diagnosis so the model stops blindly retrying.
                        cResultText = cResultText + nl + nl + cRecovery
                    ok
                ok
                return [:success = false, :error = cResultText, :message = ""]
            ok
        ok
        return [:success = false, :error = "Execution blocked", :message = ""]

    func appendToolResultToConversation(aConversation, oAIResponse, oToolResult)
        cResultText = ""
        if oToolResult[:success]
            cResultText = oToolResult[:message]
        else
            cResultText = oToolResult[:error]
        ok

        if isObject(self.oAIClient)
            if self.oAIClient.cCurrentProvider = "gemini"
                # Construct tool_call_id and tool_calls for Gemini to enable persistent history
                cToolCallID = "call_" + oAIResponse[:function_name] + "_" + clock()
                oAIResponse[:tool_call_id] = cToolCallID
                
                cArgsJSON = list2json(oAIResponse[:function_args])
                oFunctionObj = [
                    ["name", oAIResponse[:function_name]],
                    ["arguments", cArgsJSON]
                ]
                oToolCallObj = [
                    ["id", cToolCallID],
                    ["type", "function"],
                    ["function", oFunctionObj]
                ]
                oAIResponse[:tool_calls] = [oToolCallObj]
            ok

            # Always add tool calls and results to persistent history for all providers
            self.oContextEngine.addToolCallToHistory(oAIResponse[:message], oAIResponse[:tool_calls])
            self.oContextEngine.addToolResultToHistory(oAIResponse[:tool_call_id], cResultText, oAIResponse[:function_name])

            # --- Session memory wiring (fixes "doesn't remember / re-uses tools") ---
            # Populate file/code context so prepareContextMap's SESSION KNOWLEDGE
            # block is actually populated and the model stops re-listing paths.
            cToolNameLC = lower(oAIResponse[:function_name])
            if substr(cToolNameLC, "list_files") or substr(cToolNameLC, "analyze_project") or substr(cToolNameLC, "search") or substr(cToolNameLC, "grep")
                cPath = extractFirstPathArg(oAIResponse)
                if cPath = "" cPath = "." ok
                self.oContextEngine.addFileContext("explored", cPath, cResultText)
            elseif substr(cToolNameLC, "read") or substr(cToolNameLC, "read_file")
                cTarget = self.oAIClient.getValue(oAIResponse, "function_args", "")
                if type(cTarget) = "STRING" and cTarget != "" cTarget = json2list(cTarget) ok
                if type(cTarget) = "LIST"
                    for p in cTarget
                        if type(p) = "LIST" and len(p) >= 2 and lower("" + p[1]) = "filename"
                            self.oContextEngine.addCodeContext("" + p[2], cResultText, "ring")
                            exit
                        ok
                    next
                ok
            elseif substr(cToolNameLC, "write") or substr(cToolNameLC, "replace") or substr(cToolNameLC, "delete")
                cTarget = self.oAIClient.getValue(oAIResponse, "function_args", "")
                if type(cTarget) = "STRING" and cTarget != "" cTarget = json2list(cTarget) ok
                if type(cTarget) = "LIST"
                    for p in cTarget
                        if type(p) = "LIST" and len(p) >= 2 and (lower("" + p[1]) = "filename" or lower("" + p[1]) = "cfilename")
                            self.oContextEngine.addFileContext("modified", "" + p[2], cResultText)
                            exit
                        ok
                    next
                ok
            ok
        ok

        if isObject(self.oAIClient)
            if self.oAIClient.cCurrentProvider = "gemini"
                aModelParts = oAIResponse[:all_parts] 
                for pIdx = 1 to len(aModelParts)
                    if type(aModelParts[pIdx]) = "LIST"
                        for kIdx = 1 to len(aModelParts[pIdx])
                            if type(aModelParts[pIdx][kIdx]) = "LIST" and len(aModelParts[pIdx][kIdx]) >= 2
                                if aModelParts[pIdx][kIdx][1] = "functionCall"
                                    for mIdx = 1 to len(aModelParts[pIdx][kIdx][2])
                                        if type(aModelParts[pIdx][kIdx][2][mIdx]) = "LIST" and len(aModelParts[pIdx][kIdx][2][mIdx]) >= 2
                                            if aModelParts[pIdx][kIdx][2][mIdx][1] = "args"
                                                oTmpArgs = aModelParts[pIdx][kIdx][2][mIdx][2]
                                                if type(oTmpArgs) = "LIST" and len(oTmpArgs) = 0
                                                    aModelParts[pIdx][kIdx][2][mIdx][2] = [ [":_is_object", true] ]
                                                ok
                                            ok
                                        ok
                                    next
                                ok
                            ok
                        next
                    ok
                next
                Add(aConversation, [ ["role", "model"], ["parts", aModelParts] ])

                aFuncTurn = [
                    ["role", "user"],
                    ["parts", [
                        [["functionResponse", [
                            ["name", oAIResponse[:function_name]], 
                            ["response", [
                                ["name", oAIResponse[:function_name]],
                                ["content", cResultText]
                            ]]
                        ]]]
                    ]]
                ]
                Add(aConversation, aFuncTurn)
            else
                # Multi-turn conversation tracking for OpenRouter / OpenAI compatible providers
                cCallID = oAIResponse[:tool_call_id]
                if cCallID = "" cCallID = "call_" + oAIResponse[:function_name] + "_" + clock() ok
                
                aAssistantTurn = [
                    ["role", "assistant"],
                    ["content", oAIResponse[:message]],
                    ["tool_calls", oAIResponse[:tool_calls]]
                ]
                Add(aConversation, aAssistantTurn)
                
                aToolTurn = [
                    ["role", "tool"],
                    ["tool_call_id", cCallID],
                    ["name", oAIResponse[:function_name]],
                    ["content", cResultText]
                ]
                Add(aConversation, aToolTurn)
            ok
        ok
        return aConversation

    func detectAndRecordIntent(oAIResponse, nIteration)
        cFinalResponse = oAIResponse[:message]
        
        # 1. Goal Detection (Multi-language)
        if nIteration = 1 or self.cActiveGoal = ""
            aGoalPatterns = ["سأقوم بـ", "خطتي هي", "هدفنا هو", "I will", "My plan is", "The goal is", "Action Plan:"]
            for cPattern in aGoalPatterns
                if substr(cFinalResponse, cPattern)
                    nPos = substr(cFinalResponse, cPattern)
                    cRest = substr(cFinalResponse, nPos)
                    aLines = split(cRest, nl)
                    if len(aLines) > 0
                        self.setActiveGoal(aLines[1])
                        exit
                    ok
                ok
            next
        ok

        # 2. Roadmap Detection (Sequential Indicators)
        if (substr(cFinalResponse, "Action Plan") or substr(cFinalResponse, "Roadmap") or substr(cFinalResponse, "خارطة الطريق") or substr(cFinalResponse, "خطوات العمل")) and
           (substr(cFinalResponse, "1.") and substr(cFinalResponse, "2."))
            self.oTaskTracker.setRoadmap(cFinalResponse) 
            if self.oLogger != NULL 
                self.oLogger.info("  [SYSTEM] Roadmap captured and pinned to TaskTracker.") 
            ok
        ok

    func finalizeAgentResponse(oAIResponse, aToolsUsed, oContextMap, nIteration, nRequestTokens)
        cFinalResponse = oAIResponse[:message]
        cThoughtContent = oAIResponse[:thought]
        
        # Note: Goal/Roadmap now handled in real-time inside the loop via detectAndRecordIntent

        # Append tool usage note to the assistant response itself
        # (NOT as a separate "system" message — that breaks Gemini's turn alternation)
        if len(aToolsUsed) > 0
            cToolsSummary = "[Tools used: "
            for i = 1 to len(aToolsUsed)
                cToolsSummary += aToolsUsed[i]
                if i < len(aToolsUsed)  cToolsSummary += ", "  ok
            next
            cToolsSummary += "]"
            cFinalResponse += nl + cToolsSummary
        ok
        
        self.oContextEngine.addToHistory("assistant", cFinalResponse, "ai_response")

        if oTelemetry != null and oContextMap[:loop_start] > 0
            oTelemetry.recordLoop(cSessionId, nIteration, oContextMap[:loop_start], len(aToolsUsed))
        ok

        oResult = createSuccessResponse(cFinalResponse)
        oResult[:thought] = cThoughtContent
        oResult[:total_tokens] = nRequestTokens  # Per-request tokens, NOT cumulative
        
        saveHistory()
        if oLongTermMemory != null try oLongTermMemory.save() catch done ok
        
        if oStateMachine != null oStateMachine.transition(AGENT_IDLE) ok
        
        return oResult

    # ===================================================================
    # Build Contextual Prompt
    # ===================================================================
    func buildContextualPrompt(cMessage, cSystemPrompt, aContext)
        cPrompt = ""
        if cSystemPrompt != "" and cSystemPrompt != null
            cPrompt += "System: " + cSystemPrompt + nl + nl
        ok
        if type(aContext) = "LIST" and len(aContext) > 0
            cPrompt += "Context:" + nl
            for oItem in aContext
                if type(oItem) = "LIST"
                    cRole = self.oAIClient.getValue(oItem, "role", "user")
                    cContent = self.oAIClient.getValue(oItem, "content", "")
                    if cRole != "" and cContent != ""
                        cPrompt += cRole + ": " + cContent + nl
                    ok
                ok
            next
            cPrompt += nl
        ok
        if cMessage != "" and cMessage != null
            cPrompt += "User: " + cMessage
        ok
        return cPrompt

    # ===================================================================
    # Extract Tool Parameters from args object
    # ===================================================================
    func extractToolParams(cToolName, oArgs)
        if type(oArgs) = "STRING" and trim(oArgs) != ""
            try
                oArgs = json2list(oArgs)
            catch
            done
        ok

        oTool = null
        for oToolDef in oAgentTools.aAvailableTools
            if oToolDef.name = cToolName
                oTool = oToolDef
                exit
            ok
        next

        if oTool = null return [] ok

        aPositional = []
        for cParamName in oTool.parameters
            cVal = getArgValue(oArgs, cParamName)
            aPositional + [cParamName, cVal]
        next
        return aPositional

    # Extract the first plausible path/directory argument from a tool response,
    # regardless of whether function_args is a list-of-pairs or a JSON string.
    func extractFirstPathArg(oAIResponse)
        vArgs = self.oAIClient.getValue(oAIResponse, "function_args", "")
        if type(vArgs) = "STRING" and vArgs != ""
            try
                vArgs = json2list(vArgs)
            catch
                vArgs = []
            done
        ok
        if type(vArgs) != "LIST" return "" ok
        # Walk every value; return the first one that looks like a path/name
        for oItem in vArgs
            cVal = ""
            if type(oItem) = "LIST" and len(oItem) >= 2
                cVal = "" + oItem[2]
            elseif type(oItem) = "STRING"
                cVal = oItem
            ok
            cVal = trim(cVal)
            if cVal != "" and (substr(cVal, "/") or substr(cVal, "\") or substr(cVal, ".") or substr(lower(cVal), ".ring"))
                return cVal
            ok
        next
        return ""

    # ===================================================================
    # Get a value from args by key name
    # ===================================================================
    func getArgValue(oArgs, cKey)
        if type(oArgs) != "LIST" return "" ok
        # 1. Exact match (case-insensitive)
        for oItem in oArgs
            if type(oItem) = "LIST" and len(oItem) >= 2
                if type(oItem[1]) = "STRING" or type(oItem[1]) = "NUMBER"
                    if lower("" + oItem[1]) = lower("" + cKey)
                        return oItem[2]
                    ok
                ok
            ok
        next
        # 2. Alias match
        aAliases = getParamAliases(cKey)
        for cAlias in aAliases
            for oItem in oArgs
                if type(oItem) = "LIST" and len(oItem) >= 2
                    if type(oItem[1]) = "STRING" or type(oItem[1]) = "NUMBER"
                        if lower("" + oItem[1]) = lower("" + cAlias)
                            return oItem[2]
                        ok
                    ok
                ok
            next
        next
        return ""

    func getParamAliases(cKey)
        cK = lower(cKey)
        switch cK
            on "filename" return ["file", "path", "filepath", "target_file", "name"]
            on "directory" return ["dir", "path", "folder", "directory_name"]
            on "code" return ["script", "content", "ring_code", "source"]
            on "pattern" return ["query", "search_term", "text", "regex"]
            on "command" return ["cmd", "cli_command", "exec"]
            on "target" return ["target_text", "old_text", "search", "find"]
            on "replacement" return ["replacement_text", "new_text", "replace"]
            on "content" return ["text", "code", "body", "data", "markdown", "markdown_content"]
            on "url" return ["link", "uri", "website"]
            on "project_name" return ["name", "project"]
            on "search_term" return ["pattern", "query", "term", "text"]
            on "skill_name" return ["name", "skill", "skill_id", "title"]
            on "description" return ["desc", "summary", "about", "details"]
            on "markdown_content" return ["content", "markdown", "instructions", "body", "text", "skill_content"]
            on "directory_name" return ["directory", "dir", "path", "folder"]
        off
        return []

    # getValue helper
    func getValue(aList, cKey, cDefault)
        return getValueFromList(aList, cKey, cDefault)

    # A function to update the target manually or automatically.
    func setActiveGoal(cGoal)
        self.cActiveGoal = trim(cGoal)
        if self.oLogger != NULL 
            self.oLogger.info("🎯 Mission Goal Updated: " + self.cActiveGoal)
        ok
        saveProjectGoal()

    func saveProjectGoal()
        ensureDirectoryExists(APP_PATH("ai/state"))
        write(APP_PATH("ai/state/active_goal.txt"), self.cActiveGoal)

    func loadProjectGoal()
        cGoalFile = APP_PATH("ai/state/active_goal.txt")
        # Backwards compatibility check
        if not fexists(cGoalFile) and fexists(APP_PATH("logs/active_goal.txt"))
            cGoalFile = APP_PATH("logs/active_goal.txt")
        ok
        if fexists(cGoalFile)
            self.cActiveGoal = read(cGoalFile)
        ok

    
    # ===================================================================
    # Utility Functions
    # ===================================================================
    func createSuccessResponse(cMessage)
        return [
            :success = true,
            :message = cMessage,
            :thought = "",
            :error = ""
        ]
    
    func createErrorResponse(cError)
        return [
            :success = false,
            :message = "",
            :error = cError
        ]

    # ===================================================================
    # Enhanced Message with Tools
    # ===================================================================
    func enhanceMessageWithTools(cMessage, cRequestType)
        return cMessage


    # ===================================================================
    # Agent Management
    # ===================================================================
    func setCurrentProject(cProjectName)
        self.cCurrentProject = cProjectName
        self.oContextEngine.addProjectContext(cProjectName, "Current working project", [])
        see "Current project set to: " + cProjectName + nl
    
    func setCurrentFile(cFileName)
        cCurrentFile = cFileName
        see "Current file set to: " + cFileName + nl
    
    func setDebugMode(bEnabled)
        bDebugMode = bEnabled
        see "Debug mode: " + bEnabled + nl
    
    # ===================================================================
    # Bulletproof JSON Encoder — delegate to shared utility
    # ===================================================================
    func jsonEncode(oVal)
        return jsonEncodeRecursive(oVal)

    # ===================================================================
    # Security Layer — delegate to shared utilities
    # ===================================================================
    func isSensitiveTool(cName)
        return isSensitiveToolCheck(cName)

    func isReadOnlyTool(cName)
        aReadOnlyTools = ["list_files", "read_file", "search_in_files", "grep_search", 
                         "get_dependencies", "list_directory", "get_file_info", 
                         "analyze_project", "analyze_code", "git_status", "read_url"]
        if substr(cName, ":")
            pos = substr(cName, ":")
            cName = substr(cName, pos + 1)
        ok
        return find(aReadOnlyTools, lower(cName)) > 0

    func hasWritingToolCall(oAIResponse)
        if getValueFromList(oAIResponse, "type", "text") != "function_call"
            return false
        ok
        
        # Check primary tool
        cName = oAIResponse[:function_name]
        if not isReadOnlyTool(cName) return true ok
        
        # Check all parts (for parallel calling)
        aParts = oAIResponse[:all_parts]
        if type(aParts) = "LIST"
            for oPart in aParts
                if type(oPart) = "LIST"
                    oFC = getValueFromList(oPart, "functionCall", NULL)
                    if oFC != NULL
                        cSubName = getValueFromList(oFC, "name", "")
                        if not isReadOnlyTool(cSubName) return true ok
                    ok
                ok
            next
        ok
        return false

    func isPathTool(cName)
        return isPathToolCheck(cName)

    func isPathSafe(cPath)
        return isPathSafeCheck(cPath)

    func saveHistory()
        if self.cSessionId = "" self.cSessionId = generateSessionId() ok
        
        if not dirExists(APP_PATH("chats"))
            if iswindows() makedir(APP_PATH("chats")) else makedir(APP_PATH("chats")) ok
        ok
        
        cFile = APP_PATH("chats/session_" + cSessionId + ".json")
        cHistory = jsonEncode(self.oContextEngine.aConversationHistory)
        write(cFile, cHistory)
        return true

    func saveToText(cFile)
        cContent = "FLASH AI SESSION - " + cSessionId + nl
        cContent += "Date: " + date() + " " + time() + nl
        cContent += copy("=", 40) + nl + nl
        
        aHist = oContextEngine.aConversationHistory
        for oItem in aHist
            if type(oItem) != "LIST" loop ok
            cRole = "" cMsg = ""
            for pair in oItem
                if type(pair) = "LIST" and len(pair) >= 2
                    if pair[1] = "role" cRole = pair[2] ok
                    if pair[1] = "content" cMsg = pair[2] ok
                ok
            next
            cContent += upper(cRole) + ":" + nl
            cContent += cMsg + nl + nl
        next
        
        write(cFile, cContent)
        return true

    func saveToMD(cFile)
        cContent = "# FLASH AI SESSION - " + cSessionId + nl + nl
        cContent += "**Date:** " + date() + " " + time() + nl + nl
        cContent += "---" + nl + nl
        
        aHist = oContextEngine.aConversationHistory
        for oItem in aHist
            if type(oItem) != "LIST" loop ok
            cRole = "" cMsg = ""
            for pair in oItem
                if type(pair) = "LIST" and len(pair) >= 2
                    if pair[1] = "role" cRole = pair[2] ok
                    if pair[1] = "content" cMsg = pair[2] ok
                ok
            next
            
            if lower(cRole) = "user"
                cContent += "### 👤 " + cRole + nl + nl
            else
                cContent += "### 🤖 " + cRole + nl + nl
            ok
            
            cContent += cMsg + nl + nl
            cContent += "---" + nl + nl
        next
        
        write(cFile, cContent)
        return true

    func deleteSession(cFile)
        cFilePath = cFile
        if not substr(cFile, "chats/") and not substr(lower(cFile), lower(APP_PATH("chats")))
            cFilePath = APP_PATH("chats/" + cFile)
        ok
        if fexists(cFilePath)
            remove(cFilePath)
            return true
        ok
        return false

    func loadHistory(cFile)
        cFilePath = cFile
        if not substr(cFile, "chats/") and not substr(lower(cFile), lower(APP_PATH("chats")))
            cFilePath = APP_PATH("chats/" + cFile)
        ok
        if fexists(cFilePath)
            cContent = read(cFilePath)
            self.oContextEngine.aConversationHistory = self.oContextEngine.loadHistoryJSON(cContent)
            
            if substr(cFilePath, "session_")
                pos = substr(cFilePath, "session_")
                cNamePart = substr(cFilePath, pos + 8) 
                if substr(cNamePart, ".")
                    dotPos = substr(cNamePart, ".")
                    self.cSessionId = left(cNamePart, dotPos - 1)
                ok
            ok
            return true
        ok
        return false

    func setUIManager(obj)
        oUIManager = obj
        
    func setSessionAuthorized(bStatus)
        bSessionAuthorized = bStatus
        if oAgentTools != null oAgentTools.bAuthorized = bStatus ok
        if oSecurityLayer != null
            if bStatus oSecurityLayer.authorize() else oSecurityLayer.revoke() ok
        ok

    func getAgentStatus()
        cStatus = "Agent Status:" + nl
        cStatus += "Name: " + cAgentName + nl
        cStatus += "Version: " + cAgentVersion + nl
        cStatus += "Current Project: " + cCurrentProject + nl
        cStatus += "Current File: " + cCurrentFile + nl
        cStatus += "Debug Mode: " + bDebugMode + nl
        cStatus += "Language: " + cLanguagePreference + nl
        cStatus += "AI Provider: " + oAIClient.cCurrentProvider + nl
        if oStateMachine != null
            cStatus += "State Machine State: " + oStateMachine.nCurrentState + nl
        ok
        return cStatus
        
    func setLanguage(cLang)
        cLanguagePreference = cLang
        bLanguageDetected = true
        if oUIManager != null oUIManager.setLanguage(cLang) ok
        //see "Agent language set to: " + cLang + nl

    func getSavedSessions()
        aSessions = []
        try
            if dirExists(APP_PATH("chats"))
                aList = dir(APP_PATH("chats"))
                for aFile in aList
                    cName = aFile[1]
                    if left(lower(cName), 8) = "session_" and substr(lower(cName), ".json")
                        Add(aSessions, cName)
                    ok
                next
            ok
        catch
        done
        return aSessions

    func getSessionsWithPreviews(aSessions)
        aResult = []
        for cFile in aSessions
            cPath = APP_PATH("chats/" + cFile)
            cPreview = "" 
            if fexists(cPath)
                try
                    cContent = read(cPath)
                    aHistory = json2list(cContent)
                    if type(aHistory) = "LIST" and len(aHistory) > 0
                        oFinalHistory = aHistory
                        if len(aHistory) = 1 and type(aHistory[1]) = "LIST"
                            oFinalHistory = aHistory[1]
                        ok
                        for oMsg in oFinalHistory
                            cRole = getValueFromList(oMsg, "role", "")
                            cText = getValueFromList(oMsg, "content", "")
                            if lower(cRole) = "user" and trim(cText) != ""
                                cPreview = cText
                                exit
                            ok
                        next
                    ok
                catch
                done
            ok
            if trim(cPreview) = "" cPreview = cFile ok
            if len(cPreview) > 35 cPreview = left(cPreview, 32) + "..." ok
            Add(aResult, [ ["file", cFile], ["preview", cPreview] ])
        next
        return aResult

    func generateSessionId()
        return generateUniqueId()

# ===================================================================
# Task Tracker - Persistent Roadmap Management
# ===================================================================
class TaskTracker
    aTasks = []
    nCurrentTask = 1

    func setRoadmap(cPlan)
        # Convert text to task list - Improved parsing
        aLines = split(cPlan, nl)
        aNewTasks = []
        for cLine in aLines
            cLine = trim(cLine)
            # Match patterns like "1. Task", "- Task", "* Task"
            if len(cLine) > 3
                nAsc1 = ascii(cLine[1])
                if (nAsc1 >= 48 and nAsc1 <= 57 and substr(cLine, ".")) or
                   left(cLine, 2) = "- " or left(cLine, 2) = "* "
                    
                    # Clean the line
                    if substr(cLine, ".")
                        pos = substr(cLine, ".")
                        cLine = trim(substr(cLine, pos + 1))
                    else
                        cLine = trim(substr(cLine, 3))
                    ok
                    
                    if len(cLine) > 0
                        aNewTasks + [["task", cLine], ["status", "pending"], ["verified", false]]
                    ok
                ok
            ok
        next

        if len(aNewTasks) > 0
            self.aTasks = aNewTasks
            self.nCurrentTask = 1
            saveTasks()
        ok

    func getNextTask()
        if nCurrentTask <= len(aTasks)
            return aTasks[nCurrentTask][1][2] # Get Task name
        ok
        return ""

    func markTaskDone(cReason)
        if nCurrentTask <= len(aTasks)
            aTasks[nCurrentTask][2][2] = "done"
            aTasks[nCurrentTask][3][2] = true
            self.nCurrentTask++
            saveTasks()
            return true
        ok
        return false

    func saveTasks()
        ensureDirectoryExists(APP_PATH("ai/state"))
        oPlanState = [
            ["current_task", self.nCurrentTask],
            ["tasks", self.aTasks]
        ]
        cJSON = jsonEncodeValue(oPlanState)
        write(APP_PATH("ai/state/active_plan.json"), cJSON)

    func loadTasks()
        cPlanFile = APP_PATH("ai/state/active_plan.json")
        # Backwards compatibility check
        if not fexists(cPlanFile) and fexists(APP_PATH("logs/current_roadmap.json"))
            cPlanFile = APP_PATH("logs/current_roadmap.json")
        ok
        if fexists(cPlanFile)
            try
                cJSON = read(cPlanFile)
                aData = json2list(cJSON)
                if type(aData) = "LIST"
                    nCur = getValueFromList(aData, "current_task", 0)
                    if nCur > 0
                        self.nCurrentTask = nCur
                        self.aTasks = getValueFromList(aData, "tasks", [])
                    else
                        self.aTasks = aData
                        if fexists(APP_PATH("logs/current_task_idx.txt"))
                            self.nCurrentTask = 0 + read(APP_PATH("logs/current_task_idx.txt"))
                        ok
                    ok
                ok
            catch
            done
        ok