# ===================================================================
# Context Engine - Advanced Context Management System
# ===================================================================



class ContextEngine
    
    # Context storage
    aConversationHistory = []
    aProjectContext = []
    aCodeContext = []
    aFileContext = []
    
    # Configuration
    nMaxHistoryLength = 50
    nMaxContextTokens = 8000
    
    # Prompt templates
    cSystemPromptTemplate = ""
    cCodeAnalysisTemplate = ""
    cFileOperationTemplate = ""
    cProjectManagementTemplate = ""
    
    # ===================================================================
    # Constructor
    # ===================================================================
    func init()
        loadPromptTemplates()
        see "ContextEngine initialized." + nl
    
    # ===================================================================
    # Load Prompt Templates
    # ===================================================================
    func loadPromptTemplates()
        try
            # Ensure prompts directory exists
            if not dirExists(APP_PATH("prompts"))
                makedir(APP_PATH("prompts"))
            ok

            # --- System Prompt Logic ---
            if fexists(APP_PATH("prompts/system_prompt.txt"))
                cSystemPromptTemplate = read(APP_PATH("prompts/system_prompt.txt"))
            else
                cSystemPromptTemplate = getDefaultSystemPrompt()
                write(APP_PATH("prompts/system_prompt.txt"), cSystemPromptTemplate)
            ok

            # --- Code Analysis Logic ---
            if fexists(APP_PATH("prompts/code_analysis.txt"))
                cCodeAnalysisTemplate = read(APP_PATH("prompts/code_analysis.txt"))
            else
                cCodeAnalysisTemplate = getDefaultCodeAnalysisPrompt()
                write(APP_PATH("prompts/code_analysis.txt"), cCodeAnalysisTemplate)
            ok

            # --- File Operation Logic ---
            if fexists(APP_PATH("prompts/file_operation.txt"))
                cFileOperationTemplate = read(APP_PATH("prompts/file_operation.txt"))
            else
                cFileOperationTemplate = getDefaultFileOperationPrompt()
                write(APP_PATH("prompts/file_operation.txt"), cFileOperationTemplate)
            ok

            # --- Project Management Logic ---
            if fexists(APP_PATH("prompts/project_management.txt"))
                cProjectManagementTemplate = read(APP_PATH("prompts/project_management.txt"))
            else
                cProjectManagementTemplate = getDefaultProjectManagementPrompt()
                write(APP_PATH("prompts/project_management.txt"), cProjectManagementTemplate)
            ok
            
        catch
            see "Warning: Could not load prompt templates dynamically: " + cCatchError + nl
            setDefaultTemplates()
        done

    # ===================================================================
    # Create Prompt Files (Non-destructive)
    # ===================================================================
    func createPromptFiles()
        try
            if not dirExists("prompts")
                makedir("prompts")
            ok
            
            # Only write if file doesn't exist to avoid overwriting user edits
            if not fexists("prompts/system_prompt.txt")  write("prompts/system_prompt.txt", getDefaultSystemPrompt()) ok
            if not fexists("prompts/code_analysis.txt")  write("prompts/code_analysis.txt", getDefaultCodeAnalysisPrompt()) ok
            if not fexists("prompts/file_operation.txt") write("prompts/file_operation.txt", getDefaultFileOperationPrompt()) ok
            if not fexists("prompts/project_management.txt") write("prompts/project_management.txt", getDefaultProjectManagementPrompt()) ok
            
            # see "Validated prompt templates in prompts/ directory" + nl
            
        catch
            see "Error validating prompt files: " + cCatchError + nl
        done
    
    # ===================================================================
    # Add Message to Conversation History
    # ===================================================================
    func addToHistory(cRole, cMessage, cType)
        oHistoryItem = [
            ["role", cRole],
            ["content", cMessage],
            ["type", cType],
            ["timestamp", date() + " " + time()]
        ]
        aConversationHistory + oHistoryItem
        if len(aConversationHistory) > nMaxHistoryLength  del(aConversationHistory, 1)  ok
    
    func addToolCallToHistory(cContent, aToolCalls)
        oHistoryItem = [
            ["role", "assistant"],
            ["content", cContent],
            ["tool_calls", aToolCalls],
            ["type", "tool_call"],
            ["timestamp", date() + " " + time()]
        ]
        aConversationHistory + oHistoryItem
        if len(aConversationHistory) > nMaxHistoryLength  del(aConversationHistory, 1)  ok

    func addToolResultToHistory(cToolCallID, cContent, cName)
        oHistoryItem = [
            ["role", "tool"],
            ["content", cContent],
            ["tool_call_id", cToolCallID],
            ["type", "tool_result"],
            ["timestamp", date() + " " + time()]
        ]
        if cName != "" oHistoryItem + ["name", cName] ok
        
        aConversationHistory + oHistoryItem
        if len(aConversationHistory) > nMaxHistoryLength  del(aConversationHistory, 1)  ok
    
    # ===================================================================
    # Add Project Context
    # ===================================================================
    func addProjectContext(cProjectName, cDescription, aFiles)
        oProjectContext = [
            ["name", cProjectName],
            ["description", cDescription],
            ["files", aFiles],
            ["timestamp", date() + " " + time()]
        ]

        
        aProjectContext = [oProjectContext]  # Keep only current project
    
    # ===================================================================
    # Add Code Context
    # ===================================================================
    func addCodeContext(cFileName, cCode, cLanguage)
        oCodeContext = [
            ["filename", cFileName],
            ["code", cCode],
            ["language", cLanguage],
            ["timestamp", date() + " " + time()]
        ]

        
        # Add to code context array
        aCodeContext + oCodeContext
        
        # Keep only recent code contexts (max 10)
        if len(aCodeContext) > 10
            del(aCodeContext, 1)
        ok
    
    # ===================================================================
    # Add File Context
    # ===================================================================
    func addFileContext(cOperation, cFileName, cResult)
        oFileContext = [
            ["operation", cOperation],
            ["filename", cFileName],
            ["result", cResult],
            ["timestamp", date() + " " + time()]
        ]

        
        aFileContext + oFileContext
        
        # Keep only recent file operations (max 20)
        if len(aFileContext) > 20
            del(aFileContext, 1)
        ok
    
    # ===================================================================
    # Build Context for AI Request
    # ===================================================================
    /*func buildContext(cRequestType, cCurrentCode)
        aContext = []
        
        # 1. Weight-Based Sliding Window for History
        nMaxBudget = 15000
        nTotalChars = 0
        aTempHistory = []
        
        # Loop backwards to find most recent messages within budget
        for i = len(aConversationHistory) to 1 step -1
            oItem = aConversationHistory[i]
            cContent = getValueFromList(oItem, "content", "")
            
            if (nTotalChars + len(cContent)) <= nMaxBudget
                aTempHistory + oItem
                nTotalChars += len(cContent)
            else
                exit
            ok
        next
        
        # Restore chronological order
        for i = len(aTempHistory) to 1 step -1
            oItem = aTempHistory[i]
            cRole    = getValueFromList(oItem, "role", "user")
            cContent = getValueFromList(oItem, "content", "")
            
            oMsg = [ ["role", cRole], ["content", cContent] ]
            
            # Preserve Tool Call Metadata
            cID    = getValueFromList(oItem, "tool_call_id", "")
            if cID != ""  oMsg + ["tool_call_id", cID]  ok
            
            cCalls = getValueFromList(oItem, "tool_calls", "")
            if cCalls != ""  oMsg + ["tool_calls", cCalls]  ok

            aContext + oMsg
        next
        
        # Add project context if available
        if len(aProjectContext) > 0
            oProject = aProjectContext[1]
            cProjectInfo = "Current Project: " + oProject["name"] + nl +
                          "Description: " + oProject["description"] + nl +
                          "Files: " + list2str(oProject["files"])
            
            aContext + [
                ["role", "system"],
                ["content", cProjectInfo]
            ]
        ok
        
        # Add current code context
        if cCurrentCode != ""
            aContext + [
                ["role", "system"], 
                ["content", "Current Code:\n" + cCurrentCode]
            ]
        ok
        
        # Add recent file operations for file-related requests
        if cRequestType = "file_operation" and len(aFileContext) > 0
            cFileOps = "Recent File Operations:\n"
            for i = len(aFileContext) to max(1, len(aFileContext)-5) step -1
                oFileOp = aFileContext[i]
                cFileOps += oFileOp["operation"] + ": " + oFileOp["filename"] + 
                           " -> " + oFileOp["result"] + nl
            next
            
            aContext + [
                ["role", "system"],
                ["content", cFileOps]
            ]
        ok

        # 2. Dynamic State Injection (Task 2.1)
        cOSName = "Unix"
        if isWindows()  cOSName = "Windows"  ok
        
        cSystemState = "[CURRENT SYSTEM STATE]" + nl +
                      "Directory: " + currentdir() + nl +
                      "OS: " + cOSName + nl +
                      "Date: " + date() + nl + 
                      "Time: " + time()
        
        # Hidden system state block (injected at the end of context)
        aContext + [["role", "system"], ["content", cSystemState]]
        
        return aContext
*/
    # ===================================================================
    # Aggressive Context Pruning (The Token Saver)
    # ===================================================================
    func performAggressivePruning()
        nTotal = len(aConversationHistory)
        if nTotal < 5 return ok # No need to clean up at the beginning

        for i = 1 to nTotal - 3 # Leave the last 3 messages untouched (to maintain the immediate context)
            oItem = aConversationHistory[i]
            cType = getValueFromList(oItem, "type", "")
            cContent = getValueFromList(oItem, "content", "")
        
            # Exception to the plan from deletion 
            if substr(lower(cContent), "roadmap") or substr(lower(cContent), "step 1")
                loop # Don't delete the plan!
            ok
            
            # The main goals of pruning are large tool results
            if cType = "tool_result" or cType = "code_context"
                cContent = getValueFromList(oItem, "content", "")
                
                if len(cContent) > 300
                    # Convert the large result to a very small "technical summary"
                    cSummary = "[OLD TOOL RESULT: Executed successfully. Content abridged to save memory. (Original size: " + len(cContent) + " chars)]"
                    
                    # Update the content in the array
                    for j = 1 to len(oItem)
                        if oItem[j][1] = "content" 
                            oItem[j][2] = cSummary 
                            exit 
                        ok
                    next
                ok
            ok
            
            # Pruning the agent's old thoughts
            if cType = "ai_response"
                # If the response is old, we delete the large Thought and keep only the final response
                for j = 1 to len(oItem)
                    if oItem[j][1] = "thought" and len("" + oItem[j][2]) > 100
                        oItem[j][2] = "[Previous reasoning pruned]"
                        exit
                    ok
                next
            ok
        next
    ok

    # ===================================================================
    # Build Context for AI Request (Context Intelligence Subsystem)
    # ===================================================================
    func buildContext(cRequestType, cCurrentCode)
        performAggressivePruning()
        aContext =[]
        
        nMaxBudget = 15000
        nTotalChars = 0
        aTempHistory =[]
        
        nTotalMessages = len(aConversationHistory)
        
        # Loop backwards to build context dynamically
        for i = nTotalMessages to 1 step -1
            oItem = aConversationHistory[i]
            cRole = getValueFromList(oItem, "role", "user")
            cContent = getValueFromList(oItem, "content", "")
            cType = getValueFromList(oItem, "type", "chat")
            
            # [Architectural intelligence here]: Dynamic pruning based on message age 
            nAge = nTotalMessages - i  # 0 means the latest message
            
            if cType = "tool_result"
                # If the result is old (older than 4 steps), we compress it very hard
                if nAge > 4
                    cContent = truncateLongText(cContent, 500) # Hard compression
                elseif nAge > 1
                    cContent = truncateLongText(cContent, 2000) # Medium compression
                else
                    cContent = truncateLongText(cContent, 4000) # Recent, more space
                ok
            ok
            
            # User messages are never compressed unless they are very large
            if cRole = "user"
                cContent = truncateLongText(cContent, 6000)
            ok

            if (nTotalChars + len(cContent)) <= nMaxBudget
                # Update the compressed content in the temporary element
                oCompressedItem = oItem
                for j = 1 to len(oCompressedItem)
                    if oCompressedItem[j][1] = "content" oCompressedItem[j][2] = cContent ok
                next
                
                aTempHistory + oCompressedItem
                nTotalChars += len(cContent)
            else
                # If we reached the maximum, we ensure the first user message (the original request) is included by force!
                if i > 1
                    oFirstUserMsg = aConversationHistory[1]
                    if getValueFromList(oFirstUserMsg, "role", "") = "user"
                        aTempHistory + oFirstUserMsg
                    ok
                ok
                exit
            ok
        next
        
        # Restore chronological order
        for i = len(aTempHistory) to 1 step -1
            oItem = aTempHistory[i]
            cRole    = getValueFromList(oItem, "role", "user")
            cContent = getValueFromList(oItem, "content", "")
            
            oMsg = [ ["role", cRole], ["content", cContent] ]
            
            # Preserve Tool Call Metadata
            cID    = getValueFromList(oItem, "tool_call_id", "")
            if cID != ""  oMsg + ["tool_call_id", cID]  ok
            
            cCalls = getValueFromList(oItem, "tool_calls", "")
            if cCalls != ""  oMsg + ["tool_calls", cCalls]  ok

            aContext + oMsg
        next
        
        # Add project context if available
        if len(aProjectContext) > 0
            oProject = aProjectContext[1]
            cProjectInfo = "Current Project: " + oProject["name"] + nl +
                          "Description: " + oProject["description"] + nl +
                          "Files: " + list2str(oProject["files"])
            
            aContext + [["role", "system"],["content", cProjectInfo]]
        ok
        
        # Add current code context
        if cCurrentCode != ""
            aContext + [["role", "system"], ["content", "Current Code:\n" + cCurrentCode]]
        ok
        
        # Dynamic State Injection
        cOSName = "Unix"
        if isWindows()  cOSName = "Windows"  ok
        
        cSystemState = "[CURRENT SYSTEM STATE]" + nl +
                      "Directory: " + currentdir() + nl +
                      "OS: " + cOSName + nl +
                      "Date: " + date() + " | Time: " + time()
        
        aContext + [["role", "system"], ["content", cSystemState]]
        
        return aContext

    # ===================================================================
    # Smart Text Truncator (Head & Tail Preservation / Semantic Summary)
    # ===================================================================
    func truncateLongText(cText, nMaxLength)
        if len(cText) <= nMaxLength
            return cText
        ok

        # Determine if it's a tool output (often contains structured data)
        # If it looks like a directory listing or code, we can be more strategic
        if substr(cText, "Directory:") or substr(cText, "Files in")
            return "[DIRECTORY LISTING SUMMARIZED]: " + nl + 
                   left(cText, 200) + nl + "... [ + " + (len(cText) - 300) + " chars ] ..." + nl + 
                   right(cText, 100)
        ok

        # The intelligence here: we keep 30% of the beginning of the text, and 70% of its end (because errors usually appear at the end)
        nHeadLimit = floor(nMaxLength * 0.3)
        nTailLimit = floor(nMaxLength * 0.7)
        
        cHead = left(cText, nHeadLimit)
        cTail = right(cText, nTailLimit)
        
        cTruncatedMsg = nl + nl + "   ...[ SYSTEM ABRIDGED: " + (len(cText) - nMaxLength) + " characters removed to save context window ] ...   " + nl + nl
        
        return cHead + cTruncatedMsg + cTail
    
    # ===================================================================
    # Get System Prompt for Request Type
    # ===================================================================
    func getSystemPrompt(cRequestType)
        switch cRequestType
            on "code_analysis"
                return cCodeAnalysisTemplate
            on "file_operation"
                return cFileOperationTemplate
            on "project_management"
                return cProjectManagementTemplate
            other
                return cSystemPromptTemplate
        off
    
   # ===================================================================
    # Default Prompt Templates
    # ===================================================================
    func getDefaultSystemPrompt()
        return `You are FLASH AI — an ELITE AUTONOMOUS AGENT and Senior Systems Architect.
Your mission is to provide surgical, high-level technical solutions.

MISSION PROTOCOLS:
1. LATENT PLANNING (Deep Thought): Before using any tool, perform an Internal Monologue. Analyze the ripple effects of your proposed changes on the entire system.
2. DISCOVERY-FIRST: Never guess. Use list_files and grep_search extensively to understand the codebase context before proposing edits.
3. SURGICAL MODIFICATION: Prefer replace_file_content over writing entire files. Match indentation EXACTLY.
4. ERROR RESILIENCE: If a tool execution fails, do not apologize. Analyze the error message and immediately attempt a corrected technical approach.
5. QUALITY ASSURANCE: After making changes, verify them. Check file existence, run Ring code if applicable, and ensure no syntax regressions.

TONE & STYLE:
- Be technical, precise, and professional. 
- Use "Chain-of-Thought" reasoning for complex architectural decisions.
- If the user uses ARABIC, respond in ARABIC with perfect technical accuracy.
- If the user uses ENGLISH, respond in ENGLISH.

SECURITY PROTOCOL: 
- NEVER access paths outside the current directory via traverse strings.
- Verify shell commands before execution.
- Maintain data integrity at all times.

6. SELF-EVOLUTION PROTOCOL: If the user asks you to perform a task and you lack a built-in tool for it, DO NOT APOLOGIZE. You can build your own tools! Write the Ring language code for the task, then immediately use the 'evolve_new_tool' tool to register it into the system. Once registered, the tool becomes instantly available for you to use in the very next step to fulfill the user's request.
7. SELF-CORRECTION LOOP (Self-Healing): If 'evolve_new_tool' (or any execution tool) returns an error (like a syntax or compilation error from eval), DO NOT GIVE UP. Read the exact error message, fix the underlying logic or syntax in your Ring code, and try building the tool again autonomously. Never report failure to the user until you've exhausted reasonable self-correction attempts.
8. TASK DELEGATION: For complex, multi-faceted tasks (like full project documentation or architecture refactoring), use 'delegate_task' to spawn specialized agents for sub-tasks. Provide precise, actionable instructions in the task_instruction parameter to ensure high-quality reports.
9. ADVANCED PROJECT COMMANDS: Use these specialized core tools for high-level management:
- code_refactor_assistant: Analyzes and optimizes Ring code for quality and performance.
- dependency_graph_generator: Visualizes relations between project files and modules.
- automated_test_suite: Generates and runs unit tests for verified code reliability.
- context_summarizer: Provides a high-level situational report of the current project state.
10. ELEVATED PERMISSIONS: If you encounter a 'SECURITY ERROR' or 'Permission Denied' while modifying core files, ask the user to type '/authorize' in the terminal to grant you full administrative access to the codebase.
11. GOAL ADHERENCE: Always keep the 'PRIMARY OBJECTIVE' in mind. Every step you take must contribute directly to this goal. If you finish a goal, clearly state it and propose the next objective.
12. ROADMAP MANAGEMENT: When you start a complex task, define a numbered roadmap (1. Task X, 2. Task Y). The system will automatically track these tasks. When a task is completed, explicitly mention it so the TaskTracker can bridge your progress.`
    
    func getDefaultCodeAnalysisPrompt()
        return `You are a Senior Performance & Security Auditor.
        Your task is to perform a deep-dive analysis of the provided Ring source code.

AUDIT DIMENSIONS:
1. LOGICAL INTEGRITY: Identify potential runtime exceptions, off-by-one errors, or infinite loops.
2. SECURITY VULNERABILITIES: Detect command injection risks, insecure file handling, and hardcoded secrets.
3. PERFORMANCE: Optimize nested loops, suggest built-in list functions over manual iterations, and check complexity.
4. REFACTORING: Suggest architectural improvements (DRY, SOLID, and separation of concerns).

REQUIRED OUTPUT: Provide a categorized summary (Critical/Warning/Optimization) with specific code examples for fixes.`

    func getDefaultFileOperationPrompt()
        return `You are the Lead File Systems Engineer for FLASH AI.
PRIME DIRECTIVES:
1. CONTEXTUAL AWARENESS: Always read_file to check the existing structure before making any edits.
2. CLEAN OPERATIONS: When creating new files, ensure high-quality, documented code that follows the project's established style.
3. ATOMIC EDITS: Ensure that partial edits to files do not break logical blocks or leave orphaned braces.
4. VALIDATION: After any file mutation, confirm the final state of the file on disk.`
    
    func getDefaultProjectManagementPrompt()
        return `You are the Principal Architect for FLASH AI.
Your focus is the macro-level structure and maintainability of the project.

ARCHITECTURAL ANALYSIS:
1. DEPENDENCY GRAPH: Map how different modules (*.ring files) interact and load each other.
2. STRUCTURAL COHESION: Evaluate if files are placed in logical directories (src, tests, logs, config).
3. SCAFFOLDING ADAPTATION: When asked to initialize or modify the project structure, ensure it adheres to professional Ring project standards.
4. BOILERPLATE MINIMIZATION: Ensure the project is lean and doesn't contain redundant code across modules.`

    
    
    # ===================================================================
    # Set Default Templates
    # ===================================================================
    func setDefaultTemplates()
        cSystemPromptTemplate = getDefaultSystemPrompt()
        cCodeAnalysisTemplate = getDefaultCodeAnalysisPrompt()
        cFileOperationTemplate = getDefaultFileOperationPrompt()
        cProjectManagementTemplate = getDefaultProjectManagementPrompt()
    
    # ===================================================================
    # Clear Context
    # ===================================================================
    func clearHistory()
        aConversationHistory = []
        see "Conversation history cleared." + nl
    
    func clearProjectContext()
        aProjectContext = []
        see "Project context cleared." + nl
    
    func clearCodeContext()
        aCodeContext = []
        see "Code context cleared." + nl
    
    func clearFileContext()
        aFileContext = []
        see "File context cleared." + nl
    func getHistoryJSON()
        aHist = aConversationHistory
        return jsonEncodeRecursive(aHist)

    func jsonEscapeStr(cStr)
        cStr = substr(cStr, "\", "\\")
        cStr = substr(cStr, nl, "\n")
        cStr = substr(cStr, '"', '\"')
        cStr = substr(cStr, char(13), "\r")
        return cStr

    func loadHistoryJSON(cJSON)
        # We use Ring's json2list for decoding as it's more robust
        try
            aTemp = json2list(cJSON)
            if type(aTemp) = "LIST"
                if len(aTemp) > 0 and type(aTemp[1]) = "LIST"
                    # Handle cases where json2list wraps the list 
                    # OR where the list is natively the first element
                    aConversationHistory = aTemp[1]
                else
                    aConversationHistory = aTemp
                ok
            ok    
        catch
            aConversationHistory = []
        done
        return aConversationHistory
