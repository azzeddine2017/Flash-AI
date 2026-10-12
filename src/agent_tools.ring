# ===================================================================
# Agent Tools - Advanced Tools for AI Agent
# ===================================================================

class AgentTools
    
    # Tool registry
    aAvailableTools = []
    
    # Working directory
    cWorkingDirectory = ""
    
    # Security Bypass
    bAuthorized = false
    
    # Nesting depth for delegation
    nAgentDepth = 0
    
    # MCP Integration
    oMCPManager = new MCPClientManager
    
    # Persistent Long-Term Memory (Markdown-backed)
    oLongTermMemory = null

    # Skills Manager (Markdown-based Progressive Disclosure)
    oSkillsManager = null

    # ===================================================================
    # Constructor
    # ===================================================================
    func init()
        cWorkingDirectory = CurrentDir()
        registerTools()
        if oLongTermMemory = null
            try
                oLongTermMemory = new LongTermMemory
            catch
            done
        ok
        if oSkillsManager = null
            try
                oSkillsManager = new SkillsManager
            catch
            done
        ok
        see "AgentTools initialized with " + len(aAvailableTools) + " tools." + nl
    
    # ===================================================================
    # Register Available Tools
    # ===================================================================
    func registerTools()
        # File operations
        aAvailableTools + createToolFull("write_file", "Write text content to a file on disk",
            [["filename","The path of the file to write","string"],["content","The text content to write into the file","string"]],
            "file_operation")
        aAvailableTools + createToolFull("read_file", "Read and return the full text content of a file",
            [["filename","The path of the file to read","string"]],
            "file_operation")
        aAvailableTools + createToolFull("delete_file", "Delete a file from disk",
            [["filename","The path of the file to delete","string"]],
            "file_operation")
        aAvailableTools + createToolFull("list_files", "List all files and folders inside a directory",
            [["directory","The directory path to list, use '.' for current directory","string"]],
            "file_operation")
        aAvailableTools + createToolFull("create_directory", "Create a new directory folder",
            [["directory_name","Name or path of the directory to create","string"]],
            "file_operation")
        
        aAvailableTools + createToolFull("replace_file_content", "Replace a specific text block in a file with new content (Surgical Edit)",
            [["filename","The path of the file to edit","string"], ["target","The exact text block to find and replace","string"], ["replacement","The new text to put instead","string"]],
            "file_operation")

        aAvailableTools + createToolFull("grep_search", "A powerful search to find a pattern across the whole project files",
            [["pattern","The text or regex to search for","string"], ["directory","The directory to start search from (default: .)","string"]],
            "search_operation")

        # Code operations
        aAvailableTools + createToolFull("run_ring_code", "Execute Ring language source code and return its output",
            [["code","The Ring source code to execute","string"]],
            "code_execution")
        aAvailableTools + createToolFull("analyze_code", "Analyze Ring source code for errors and improvements",
            [["code","The Ring source code to analyze","string"]],
            "code_analysis")
        aAvailableTools + createToolFull("format_code", "Format Ring source code with proper indentation",
            [["code","The Ring source code to format","string"]],
            "code_formatting")

        # Project operations
        aAvailableTools + createToolFull("create_project", "Create a new Ring project directory structure with boilerplate",
            [["project_name","Name of the new project","string"],["project_type","Type of project (e.g. cli, gui, web)","string"]],
            "project_management")
        aAvailableTools + createToolFull("analyze_project", "Analyze a project's directory structure and summarize it",
            [["project_path","The root path of the project to analyze","string"]],
            "project_analysis")

        # Git operations
        aAvailableTools + createToolFull("git_init", "Initialize a new Git repository in the current directory",
            [],
            "git_operation")
        aAvailableTools + createToolFull("git_status", "Get the current Git repository status",
            [],
            "git_operation")
        aAvailableTools + createToolFull("git_add", "Stage files for a Git commit",
            [["files","File pattern to add, e.g. '.' for all files","string"]],
            "git_operation")
        aAvailableTools + createToolFull("git_commit", "Commit staged changes with a commit message",
            [["message","The commit message describing the changes","string"]],
            "git_operation")

        # System operations
        aAvailableTools + createToolFull("execute_command", "Execute an operating system shell command securely",
            [["command","The shell command to execute","string"]],
            "system_operation")
        aAvailableTools + createToolFull("search_in_files", "Search for a text pattern across files in a directory",
            [["search_term","The text or pattern to search for","string"],["directory","The directory to search in, use '.' for current directory","string"]],
            "search_operation")
        
        # New: Web Operations
        aAvailableTools + createToolFull("read_url", "Download and read the text content of a URL",
            [["url","The full URL to fetch content from","string"]],
            "web_operation")

        # New: Self-Evolution Operations
        aAvailableTools + createToolFull("evolve_new_tool", 
            "Create and register a NEW tool dynamically in the system. Use this when you need a feature that is missing.",
            [["tool_name", "Unique name for the tool function", "string"],
             ["description", "Clear explanation of what the tool does for the AI's reference", "string"],
             ["params_json", "JSON list of parameters: [['name','desc','type'],...]", "string"],
             ["ring_code", "The full Ring source code for the tool function", "string"]],
            "self_evolution")
            
        # New: Sub-Task Delegation
        aAvailableTools + createToolFull("delegate_task",
            "Spawn a new sub-agent instance with an empty initial memory to perform a heavy sub-task and return the final report. Essential for splitting large coding goals.",
            [["task_instruction","The detailed plan and instructions for this sub-agent","string"]],
            "agent_delegation")

        # Skills Management (Markdown-based Progressive Disclosure in skills/)
        aAvailableTools + createToolFull("list_skills", 
            "List all specialized Markdown skills available in the skills/ library with their purpose and scope",
            [],
            "skills_management")

        aAvailableTools + createToolFull("activate_skill", 
            "Activate and read the specialized Markdown instructions, rules, and workflows from a skill in skills/ (e.g. ring_code_master, ring_gui_development, code_refactoring)",
            [["skill_name","Unique identifier of the skill to activate and read","string"]],
            "skills_management")


        aAvailableTools + createToolFull("save_skill", 
            "Create a new skill or update an existing skill as a structured Markdown document in skills/<skill_name>/SKILL.md",
            [["skill_name","Unique name for the skill (e.g. web_scraping, data_analysis)","string"],
             ["description","Clear 1-2 sentence description explaining when and why the agent should activate this skill","string"],
             ["markdown_content","The full Markdown text containing guidelines, rules, and examples","string"]],
            "skills_management")

        aAvailableTools + createToolFull("delete_skill", 
            "Delete an obsolete or unwanted skill from the skills/ directory",
            [["skill_name","Name of the skill to delete","string"]],
            "skills_management")

        # Long-Term Markdown-Backed Memory
        aAvailableTools + createToolFull("remember_fact", 
            "Permanently store a project fact, user preference, architecture rule, or code pattern into long-term memory (synced to MEMORY.md)",
            [["category","Category: user_preference, project_fact, code_pattern, error_pattern, file_knowledge, or general","string"],
             ["fact","The exact statement or insight to remember","string"],
             ["importance","Importance score from 1 to 10 (default: 5)","number"]],
            "memory_management")

        aAvailableTools + createToolFull("recall_memory", 
            "Search long-term memory for stored facts and guidelines matching query keywords",
            [["query","Search terms or keywords","string"],
             ["max_results","Maximum number of memories to return (default: 5)","number"]],
            "memory_management")

        aAvailableTools + createToolFull("view_memory", 
            "View long-term knowledge base formatted in Markdown (optionally filter by category)",
            [["category","Optional category to filter by (leave empty for entire knowledge base)","string"]],
            "memory_management")

        aAvailableTools + createToolFull("forget_fact", 
            "Remove memories matching a keyword or phrase from persistent storage",
            [["keyword","Keyword or phrase identifying memories to remove","string"]],
            "memory_management")
        
        # Bootstrap Custom Tools
        loadCustomTools()
    
    # ===================================================================
    # Bootstrap Loading (Self-Healing / Persistent Memory)
    # ===================================================================
    func loadCustomTools()
        try
            cCustomDir = APP_PATH("custom_tools")
            if not dirExists(cCustomDir) return ok
            
            aFiles = dir(cCustomDir)
            for item in aFiles
                # dir() returns [filename, is_dir]
                cFile = item[1]
                if item[2] = 0 and right(cFile, 5) = ".ring"
                    cToolName = substr(cFile, 1, len(cFile)-5)
                    cJsonPath = cCustomDir + "/" + cToolName + ".json"
                    
                    if fexists(cJsonPath)
                        try
                            cJsonCode = read(cJsonPath)
                            oMeta = json2list(cJsonCode)
                            if type(oMeta) = "LIST" and len(oMeta) > 0
                                oObj = oMeta
                                cName = getValueFromList(oObj, "name", cToolName)
                                cDesc = getValueFromList(oObj, "desc", "Autonomously evolved tool")
                                aParams = getValueFromList(oObj, "params", [])
                                
                                cRingCode = read(cCustomDir + "/" + cFile)
                                
                                # Safety Check: Do not redefine the function if already loaded globally
                                bExists = false
                                aGF = functions()
                                for cf in aGF
                                    if lower(cf) = lower(cName)
                                        bExists = true
                                        exit
                                    ok
                                next
                                
                                if not bExists
                                    try
                                        eval(cRingCode)
                                    catch
                                        # Optionally suppress runtime catch
                                    done
                                ok
                                
                                oNewTool = createToolFull(cName, cDesc, aParams, "custom_tool")
                                Add(aAvailableTools, oNewTool)
                                see "  [+] Bootstrapped Tool: " + cName + nl
                            ok
                        catch
                            see "  [-] Failed to load metadata for: " + cToolName + nl
                        done
                    ok
                ok
            next
        catch
            see "  [-] Error during custom tools bootstrap: " + cCatchError + nl
        done    # ===================================================================
    # Create Tool Definition (simple - for backward compatibility)
    # ===================================================================
    func createTool(cName, cDescription, aParameters, cCategory)
        oTool = new stdclass
        oTool.name = cName
        oTool.description = cDescription
        # Convert plain name list to [[name,desc,type]] format
        aParamFull = []
        for cP in aParameters
            aParamFull + [cP, "", "string"]
        next
        oTool.parameters = aParameters
        oTool.paramDescriptions = aParamFull
        oTool.category = cCategory
        return oTool

    # ===================================================================
    # Create Tool Definition (full - with parameter descriptions)
    # ===================================================================
    func createToolFull(cName, cDesc, aParamDefs, cCategory)
        # aParamDefs = list of [name, description, type] triples 
        # OR list of objects [ [:name="", :desc="", :type=""], ... ]
        oTool = new stdclass
        oTool.name = cName
        oTool.description = cDesc
        
        # Extract plain parameter names list
        aParamNames = []
        aFinalDefs = [] # Normalized to [name, desc, type] triples
        
        if type(aParamDefs) = "LIST"
            for aDef in aParamDefs
                cParamName = ""
                cParamDesc = ""
                cParamType = "string"
                
                # Case 1: Triple [name, desc, type]
                if type(aDef) = "LIST" and len(aDef) >= 3
                    cParamName = "" + aDef[1]
                    cParamDesc = "" + aDef[2]
                    cParamType = "" + aDef[3]
                # Case 2: Object-style list (association list of [key, val])
                elseif type(aDef) = "LIST" and len(aDef) > 0 and type(aDef[1]) = "LIST"
                    cParamName = getValueFromList(aDef, "name", "")
                    cParamDesc = getValueFromList(aDef, "desc", "")
                    if cParamDesc = "" cParamDesc = getValueFromList(aDef, "description", "") ok
                    cParamType = getValueFromList(aDef, "type", "string")
                # Case 3: Pair [name, desc] (positional or partial)
                elseif type(aDef) = "LIST" and len(aDef) = 2
                    cParamName = "" + aDef[1]
                    cParamDesc = "" + aDef[2]
                ok
                
                if trim(cParamName) != ""
                    Add(aParamNames, trim(cParamName))
                    Add(aFinalDefs, [trim(cParamName), cParamDesc, cParamType])
                ok
            next
        ok
        
        oTool.parameters = aParamNames
        oTool.paramDescriptions = aFinalDefs
        oTool.category = cCategory
        return oTool

    # ===================================================================
    # Build Gemini Function Declarations as JSON string
    # Built manually to avoid Ring list2json turning {} into []
    # ===================================================================
    func getFunctionDeclsJSON()
        cJSON = "["
        bFirst = true
        for oTool in aAvailableTools
            if trim(oTool.name) = ""  loop  ok
            if not bFirst  cJSON += ","  ok
            bFirst = false
            cDesc = oTool.description
            cJSON += '{"name":"' + trim(oTool.name) + '",'
            cJSON += '"description":"' + cDesc + '",'
            cJSON += '"parameters":{"type":"object"'
            
            aValidParams = []
            if len(oTool.paramDescriptions) > 0
                for aDef in oTool.paramDescriptions
                    if type(aDef) = "LIST" and len(aDef) > 0
                        if type(aDef[1]) = "LIST" aDef = aDef[1] ok
                        if type(aDef[1]) = "STRING" and trim(aDef[1]) != ""
                            aValidParams + aDef
                        ok
                    ok
                next
            ok
            
            if len(aValidParams) > 0
                cJSON += ',"properties":{'
                bFirstProp = true
                for aDef in aValidParams
                    if not bFirstProp  cJSON += ","  ok
                    bFirstProp = false
                    cPType = aDef[3]
                    if cPType = ""  cPType = "string"  ok
                    cJSON += '"' + trim(aDef[1]) + '":{"type":"' + cPType + '","description":"' + aDef[2] + '"}'
                next
                cJSON += "},"
                cJSON += '"required":['
                bFirstReq = true
                for aDef in aValidParams
                    if not bFirstReq  cJSON += ","  ok
                    bFirstReq = false
                    cJSON += '"' + trim(aDef[1]) + '"'
                next
                cJSON += "]"
            else
                cJSON += ',"properties":{}'
            ok
            cJSON += "}}"
        next
        cJSON += "]"
        return cJSON

    # ===================================================================
    # Build OpenAI-Compatible Tool Declarations as JSON string
    # Used for OpenRouter, Claude, and standard OpenAI models
    # ===================================================================
    func getOpenAIToolsJSON()
        cJSON = "["
        bFirst = true
        for oTool in aAvailableTools
            if trim(oTool.name) = ""  loop  ok
            if not bFirst  cJSON += ","  ok
            bFirst = false
            cDesc = oTool.description
            cJSON += '{"type":"function","function":{'
            cJSON += '"name":"' + trim(oTool.name) + '",'
            cJSON += '"description":"' + cDesc + '",'
            cJSON += '"parameters":{"type":"object"'
            
            aValidParams = []
            if len(oTool.paramDescriptions) > 0
                for aDef in oTool.paramDescriptions
                    if type(aDef) = "LIST" and len(aDef) > 0
                        if type(aDef[1]) = "LIST" aDef = aDef[1] ok
                        if type(aDef[1]) = "STRING" and trim(aDef[1]) != ""
                            aValidParams + aDef
                        ok
                    ok
                next
            ok
            
            if len(aValidParams) > 0
                cJSON += ',"properties":{'
                bFirstProp = true
                for aDef in aValidParams
                    if not bFirstProp  cJSON += ","  ok
                    bFirstProp = false
                    cPType = aDef[3]
                    if cPType = ""  cPType = "string"  ok
                    cJSON += '"' + trim(aDef[1]) + '":{"type":"' + cPType + '","description":"' + aDef[2] + '"}'
                next
                cJSON += "},"
                cJSON += '"required":['
                bFirstReq = true
                for aDef in aValidParams
                    if not bFirstReq  cJSON += ","  ok
                    bFirstReq = false
                    cJSON += '"' + trim(aDef[1]) + '"'
                next
                cJSON += "]"
            else
                cJSON += ',"properties":{}'
            ok
            cJSON += "}}}"
        next
        cJSON += "]"
        return cJSON


    # ===================================================================
    # Universal Dispatcher Interface (Dispatcher Pattern)
    # ===================================================================
    func execute(cToolName, aParameters)
        return executeTool(cToolName, aParameters)

    # ===================================================================
    # Execute Tool
    # ===================================================================
    func executeTool(cToolName, aParameters)
        # Normalize parameters (Task Fix: handle both positional and associative)
        aParameters = normalizeParameters(cToolName, aParameters)
        
        try

            switch cToolName
                # Agent Delegation
                on "delegate_task"
                    nDepth = nAgentDepth 
                    return delegateTask(getValueFromList(aParameters, "task_instruction", ""), nDepth)

                # File operations (with centralized security checks)
                on "write_file"
                    cFN = getValueFromList(aParameters, "filename", "")
                    if cFN = "" cFN = getValueFromList(aParameters, "path", "") ok
                    if cFN = "" cFN = getValueFromList(aParameters, "file", "") ok
                    if isCoreProtected(cFN)
                        return createErrorResult("SECURITY ERROR: Modification of core agent files is prohibited.")
                    ok
                    cContent = getValueFromList(aParameters, "content", "")
                    if cContent = "" cContent = getValueFromList(aParameters, "text", "") ok
                    return writeFile(cFN, cContent)
                on "read_file"
                    cFN = getValueFromList(aParameters, "filename", "")
                    if cFN = "" cFN = getValueFromList(aParameters, "path", "") ok
                    if cFN = "" cFN = getValueFromList(aParameters, "file", "") ok
                    return readFile(cFN)
                on "delete_file"
                    cFN = getValueFromList(aParameters, "filename", "")
                    if cFN = "" cFN = getValueFromList(aParameters, "path", "") ok
                    if cFN = "" cFN = getValueFromList(aParameters, "file", "") ok
                    if isCoreProtected(cFN)
                        return createErrorResult("SECURITY ERROR: Deletion of core agent files is prohibited.")
                    ok
                    return deleteFile(cFN)
                on "list_files"
                    return listFiles(getValueFromList(aParameters, "directory", "."))
                on "create_directory"
                    cDir = getValueFromList(aParameters, "directory_name", "")
                    if cDir = "" cDir = getValueFromList(aParameters, "directory", "") ok
                    if cDir = "" cDir = getValueFromList(aParameters, "path", "") ok
                    return createDirectory(cDir)
                on "replace_file_content"
                    cFN = getValueFromList(aParameters, "filename", "")
                    if isCoreProtected(cFN)
                        return createErrorResult("SECURITY ERROR: Modification of core agent files is prohibited.")
                    ok
                    return replace_file_content(cFN, 
                                                getValueFromList(aParameters, "target", ""), 
                                                getValueFromList(aParameters, "replacement", ""))
                on "grep_search"
                    return grep_search(getValueFromList(aParameters, "pattern", ""), 
                                       getValueFromList(aParameters, "directory", "."))
                
                # Code operations → src/tools/code_tools.ring
                on "run_ring_code"
                    return runRingCode(getValueFromList(aParameters, "code", ""))
                on "analyze_code"
                    return analyzeCode(getValueFromList(aParameters, "code", ""))
                on "format_code"
                    return formatCode(getValueFromList(aParameters, "code", ""))
                
                # Project operations → src/tools/project_tools.ring
                on "create_project"
                    return createProject(getValueFromList(aParameters, "project_name", ""), 
                                         getValueFromList(aParameters, "project_type", "cli"))
                on "analyze_project"
                    return analyzeProject(getValueFromList(aParameters, "project_path", "."))
                
                # Git operations → src/tools/project_tools.ring
                on "git_init"
                    return gitInit()
                on "git_status"
                    return gitStatus()
                on "git_add"
                    return gitAdd(getValueFromList(aParameters, "files", "."))
                on "git_commit"
                    return gitCommit(getValueFromList(aParameters, "message", "Commit changes"))
                
                # System operations → src/tools/system_tools.ring
                on "execute_command"
                    cCmdRaw = getValueFromList(aParameters, "command", "")
                    # Centralized Security: Check for blacklisted commands
                    if isCommandBlacklisted(cCmdRaw)
                        return createErrorResult("SECURITY ERROR: Command blacklisted.")
                    ok
                    return executeCommand(cCmdRaw)
                on "search_in_files"
                    return searchInFiles(getValueFromList(aParameters, "search_term", ""), 
                                         getValueFromList(aParameters, "directory", "."))
                on "read_url"
                    return read_url(getValueFromList(aParameters, "url", ""))
                
                # Self-Evolution (kept in AgentTools — accesses class state)
                on "evolve_new_tool"
                    return evolve_new_tool(
                        getValueFromList(aParameters, "tool_name", ""), 
                        getValueFromList(aParameters, "description", ""), 
                        getValueFromList(aParameters, "params_json", ""), 
                        getValueFromList(aParameters, "ring_code", ""))

                # Skills Management (Markdown-based)
                on "list_skills"
                    return listSkills()
                on "activate_skill" on "read_skill"
                    cSkillName = getValueFromList(aParameters, "skill_name", "")
                    if cSkillName = "" cSkillName = getValueFromList(aParameters, "name", "") ok
                    if cSkillName = "" cSkillName = getValueFromList(aParameters, "skill", "") ok
                    return activateSkill(cSkillName)
                on "save_skill"
                    cSkillName = getValueFromList(aParameters, "skill_name", "")
                    if cSkillName = "" cSkillName = getValueFromList(aParameters, "name", "") ok
                    if cSkillName = "" cSkillName = getValueFromList(aParameters, "skill", "") ok
                    cDesc = getValueFromList(aParameters, "description", "")
                    if cDesc = "" cDesc = getValueFromList(aParameters, "desc", "") ok
                    cMD = getValueFromList(aParameters, "markdown_content", "")
                    if cMD = "" cMD = getValueFromList(aParameters, "content", "") ok
                    if cMD = "" cMD = getValueFromList(aParameters, "markdown", "") ok
                    if cMD = "" cMD = getValueFromList(aParameters, "instructions", "") ok
                    return saveSkill(cSkillName, cDesc, cMD)
                on "modify_skill"
                    # Backward compatibility for modify_skill
                    cName = getValueFromList(aParameters, "skill_name", "")
                    if cName = "" cName = getValueFromList(aParameters, "name", "") ok
                    cDesc = getValueFromList(aParameters, "description", "")
                    if cDesc = "" cDesc = getValueFromList(aParameters, "desc", "") ok
                    cMD = getValueFromList(aParameters, "markdown_content", "")
                    if cMD = "" cMD = getValueFromList(aParameters, "content", "") ok
                    if cMD = "" cMD = getValueFromList(aParameters, "ring_code", "") ok
                    return saveSkill(cName, cDesc, cMD)
                on "delete_skill"
                    cSkillName = getValueFromList(aParameters, "skill_name", "")
                    if cSkillName = "" cSkillName = getValueFromList(aParameters, "name", "") ok
                    return deleteSkill(cSkillName)

                # Memory Management
                on "remember_fact"
                    return rememberFact(
                        getValueFromList(aParameters, "category", "general"),
                        getValueFromList(aParameters, "fact", ""),
                        getValueFromList(aParameters, "importance", 5))
                on "recall_memory"
                    return recallMemory(
                        getValueFromList(aParameters, "query", ""),
                        getValueFromList(aParameters, "max_results", 5))
                on "view_memory"
                    return viewMemory(getValueFromList(aParameters, "category", ""))
                on "forget_fact"
                    return forgetFact(getValueFromList(aParameters, "keyword", ""))
                other
                    # DYNAMIC TOOL HANDLING (Task 1 & Task 3 Fix)
                    # For dynamic tools, we look up the definition to see what parameters to pass
                    oToolDef = NULL
                    for oT in aAvailableTools
                        if oT.name = cToolName
                            oToolDef = oT
                            exit
                        ok
                    next
                    
                    if oToolDef != NULL
                        if isattribute(oToolDef, "is_mcp")
                            if oToolDef.is_mcp
                                aRes = oMCPManager.callTool(oToolDef.mcp_client, oToolDef.mcp_name, aParameters)
                                if aRes[1]
                                    return createSuccessResult(aRes[2])
                                else
                                    return createErrorResult(aRes[2])
                                ok
                            ok
                        ok
                    ok
                    
                    if isfunction(cToolName)
                        if oToolDef != NULL
                            # Build call using global argument passing to eliminate string escaping bugs
                            $g_dyn_call_args = []
                            for i = 1 to len(oToolDef.parameters)
                                cParamName = oToolDef.parameters[i]
                                cVal = getValueFromList(aParameters, cParamName, "")
                                $g_dyn_call_args + cVal
                            next
                            
                            cCall = cToolName + "("
                            for i = 1 to len($g_dyn_call_args)
                                if i > 1 cCall += "," ok
                                cCall += "$g_dyn_call_args[" + i + "]"
                            next
                            cCall += ")"
                            
                            try
                                oDynResult = eval("return " + cCall)
                                # Global Safety Wrap: ensures compatibility with both standard and custom tool results
                                if type(oDynResult) != "LIST"
                                    return createSuccessResult("" + oDynResult)
                                ok
                                return oDynResult
                            catch
                                return createErrorResult("Dynamic execution error: " + cCatchError)
                            done
                        else
                            # Fallback call if no definition (less robust)
                            try
                                return eval("return " + cToolName + "(aParameters)")
                            catch
                                return createErrorResult("Dynamic fallback error: " + cCatchError)
                            done
                        ok
                    ok
                    return createErrorResult("Unknown tool: " + cToolName)
            off
            
        catch
            return createErrorResult("Tool execution failed: " + cCatchError)
        done

    func jsonEscape(cStr)
        return jsonEscapeStr(cStr)
    
    # ===================================================================
    # Tool implementations have been extracted to modular files:
    #   src/tools/file_tools.ring    — writeFile, readFile, deleteFile, listFiles, etc.
    #   src/tools/code_tools.ring    — runRingCode, analyzeCode, formatCode
    #   src/tools/project_tools.ring — createProject, analyzeProject, git operations
    #   src/tools/system_tools.ring  — executeCommand, searchInFiles, read_url
    # Security checks (isCoreProtected) are centralized in the dispatcher above.
    # Result helpers (createSuccessResult, createErrorResult) are global in utils.ring.
    # ===================================================================

    # ===================================================================
    # Get Available Tools List
    # ===================================================================
    func getToolsList()
        cToolsList = "Available Tools:" + nl + nl

        cCurrentCategory = ""
        for oTool in aAvailableTools
            if oTool.category != cCurrentCategory
                cCurrentCategory = oTool.category
                cToolsList += "=== " + cCurrentCategory + " ===" + nl
            ok

            cToolsList += "• " + oTool.name + ": " + oTool.description + nl
        next

        return cToolsList

    # ===================================================================
    # Validate Tool Parameters
    # ===================================================================
    func validateToolParameters(cToolName, aParameters)
        # Find tool definition
        oTool = null
        for oToolDef in aAvailableTools
            if oToolDef.name = cToolName
                oTool = oToolDef
                exit
            ok
        next

        if oTool = null
            return [false, "Tool not found: " + cToolName]
        ok

        # Check parameter count
        aRequiredParams = oTool.parameters
        
        # Exception for list_files, run_ring_code which can guess defaults
        if cToolName = "list_files" and len(aParameters) = 0
            # Allow 0 parameters for list_files defaulting to current directory
        elseif len(aParameters) != len(aRequiredParams)
            return [false, "Expected " + len(aRequiredParams) + " parameters, got " + len(aParameters)]
        ok


        return [true, "Parameters valid"]

    # ===================================================================
    # Build and Register Tool (Self-Evolution)
    # ===================================================================
    func evolve_new_tool(cToolName, cDescription, cParamsJSON, cRingCode)
        try
            cToolName = trim(cToolName)
            if cToolName = ""
                return createErrorResult("Error: tool_name cannot be empty. You must provide a valid name.")
            ok
            
            # Ensure folder exists
            ensureDirectoryExists(APP_PATH("custom_tools"))

             # Parse parameters
            aParams = []
            if type(cParamsJSON) = "LIST"
                aParams = cParamsJSON
            else
                try
                    aParams = json2list(cParamsJSON)
                catch
                    # Fallback parser for slightly malformed JSON or Ring-style lists
                    if type(cParamsJSON) = "STRING"
                        cParamsJSON = substr(cParamsJSON, "'", '"')
                    ok
                    try
                        aParams = json2list(cParamsJSON)
                    catch
                            # Final fallback: assume single string if no brackets
                            cParamsJSONTrim = trim("" + cParamsJSON)
                        if cParamsJSONTrim != "" and substr(cParamsJSONTrim, "[") = 0
                            aParams = [[cParamsJSONTrim, "Parameter", "string"]]
                        elseif cParamsJSONTrim = ""
                            aParams = []
                        else
                            return createErrorResult("Invalid params_json. Format: [['name','desc','type'],...]")
                        ok
                    done
                done
            ok
            
            # Ensure param names are not empty
            if type(aParams) = "LIST"
                for i = 1 to len(aParams)
                    if len(aParams[i]) > 0 and type(aParams[i][1]) = "STRING"
                        if trim(aParams[i][1]) = ""
                            aParams[i][1] = "param" + i
                        ok
                    ok
                next
            ok
            
            # --- SECURITY: Sanitize tool name (prevent path traversal) ---
            cToolName = sanitizeShellArg(cToolName)
            cToolName = substr(cToolName, "/", "")
            cToolName = substr(cToolName, "\", "")
            cToolName = substr(cToolName, "..", "")
            if cToolName = ""
                return createErrorResult("Tool name is invalid after sanitization.")
            ok
            
            # --- SECURITY: Validate code before eval (sandbox check) ---
            if not bAuthorized
                aValidation = validateToolCode(cRingCode)
                if not aValidation[1]
                    return createErrorResult("EVOLUTION BLOCKED: " + aValidation[2] + 
                        " Use /authorize to grant full permissions if needed.")
                ok
            ok
            
            # Save and Hot-Reload
            cFilePath = APP_PATH("custom_tools/" + cToolName + ".ring")
            write(cFilePath, cRingCode)
            
            # Isolated Compiler Verification via subprocess
            aCheck = safeSystem("ring -c " + cFilePath, 10)
            if aCheck[1] = false
                try remove(cFilePath) catch done
                return createErrorResult("Compiler syntax error in tool '" + cToolName + "':" + nl + aCheck[2] + nl + "Fix the code syntax and try evolving again.")
            ok
            
            # Register Tool
            oNewTool = createToolFull(cToolName, cDescription, aParams, "custom_tool")
            Add(aAvailableTools, oNewTool)

            # Ensure normalized triple-style params for metadata saving
            aTripleParams = oNewTool.paramDescriptions

            # Save Metadata for Bootstrap Loading
            oMetadata = [
                ["name", cToolName],
                ["desc", cDescription],
                ["params", aTripleParams]
            ]
            write(APP_PATH("custom_tools/" + cToolName + ".json"), jsonEncodeValue(oMetadata))
            
            # Try to evaluate into current runtime
            try
                eval(cRingCode)
            catch
                cError = lower(cCatchError)
                if not (substr(cError, "redefinition") or substr(cError, "already defined") or substr(cError, "redeclaration"))
                    return createErrorResult("Evolution runtime loading error: " + cCatchError)
                ok
            done

            return createSuccessResult("Tool '" + cToolName + "' successfully added to the agent's arsenal.")
        catch
            return createErrorResult("Evolution error: " + cCatchError)
        done

    # ===================================================================
    # Skills Management Implementation (Markdown-Based)
    # ===================================================================
    func listSkills()
        if oSkillsManager = null
            oSkillsManager = new SkillsManager
        ok
        aSkills = oSkillsManager.getSkills()
        cOutput = "# FLASH AI - Skills Library (`skills/`)" + nl + nl
        cOutput += "Total Available Skills: " + len(aSkills) + nl + nl
        if len(aSkills) = 0
            cOutput += "_No skills found in `skills/`. You can create one using `save_skill`._" + nl
            return createSuccessResult(cOutput)
        ok
        for oS in aSkills
            cName = getValueFromList(oS, "name", "")
            cTitle = getValueFromList(oS, "title", cName)
            cDesc = getValueFromList(oS, "description", "")
            cPath = getValueFromList(oS, "path", "")
            cOutput += "### " + cTitle + " (`" + cName + "`)" + nl
            cOutput += "- **Description:** " + cDesc + nl
            cOutput += "- **Location:** `" + cPath + "`" + nl + nl
        next
        cOutput += "> *To load instructions for any skill, call `activate_skill(skill_name)`.*"
        return createSuccessResult(cOutput)

    func activateSkill(cSkillName)
        if oSkillsManager = null
            oSkillsManager = new SkillsManager
        ok
        cSkillName = trim(cSkillName)
        if cSkillName = ""
            return createErrorResult("skill_name cannot be empty.")
        ok
        aRes = oSkillsManager.getSkill(cSkillName)
        if aRes[1] = true
            cOut = "[ACTIVATED SKILL: " + cSkillName + "]" + nl + nl +
                   aRes[2] + nl + nl +
                   "[END OF SKILL INSTRUCTIONS - Apply the above rules to your execution]"
            return createSuccessResult(cOut)
        else
            return createErrorResult(aRes[2])
        ok

    func readSkill(cSkillName)
        return activateSkill(cSkillName)

    func saveSkill(cSkillName, cDescription, cMarkdownContent)
        if oSkillsManager = null
            oSkillsManager = new SkillsManager
        ok
        aRes = oSkillsManager.saveSkill(cSkillName, cDescription, cMarkdownContent)
        if aRes[1] = true
            return createSuccessResult(aRes[2])
        else
            return createErrorResult(aRes[2])
        ok

    func modifySkill(cSkillName, cDescription, cParamsJSON, cRingCode)
        # Compatibility wrapper directing to saveSkill
        cContent = cRingCode
        if cContent = "" cContent = cParamsJSON ok
        return saveSkill(cSkillName, cDescription, cContent)

    func deleteSkill(cSkillName)
        if oSkillsManager = null
            oSkillsManager = new SkillsManager
        ok
        aRes = oSkillsManager.deleteSkill(cSkillName)
        if aRes[1] = true
            return createSuccessResult(aRes[2])
        else
            return createErrorResult(aRes[2])
        ok

    # ===================================================================
    # Long-Term Memory Implementation (Markdown Backed)
    # ===================================================================
    func rememberFact(cCategory, cFact, nImportance)
        if oLongTermMemory = null
            oLongTermMemory = new LongTermMemory
        ok
        if type(nImportance) = "STRING"
            nImportance = 0 + nImportance
        ok
        if nImportance = 0  nImportance = 5  ok
        oLongTermMemory.remember(cCategory, cFact, nImportance)
        oLongTermMemory.syncMarkdownFile()
        return createSuccessResult("Fact recorded in long-term memory under [" + cCategory + "]: " + cFact)

    func recallMemory(cQuery, nMaxResults)
        if oLongTermMemory = null
            oLongTermMemory = new LongTermMemory
        ok
        if type(nMaxResults) = "STRING"
            nMaxResults = 0 + nMaxResults
        ok
        if nMaxResults <= 0  nMaxResults = 5  ok
        aResults = oLongTermMemory.recall(cQuery, nMaxResults)
        if len(aResults) = 0
            return createSuccessResult("No memories found matching query: '" + cQuery + "'")
        ok
        cOut = "# Recalled Memories for '" + cQuery + "':" + nl + nl
        for oMem in aResults
            cCat = getValueFromList(oMem, "category", "general")
            cFact = getValueFromList(oMem, "fact", "")
            nImp = getValueFromList(oMem, "importance", 5)
            cCreated = getValueFromList(oMem, "created", "")
            cOut += "- **[" + cCat + "]** (Importance: " + nImp + "/10): " + cFact + " *(saved: " + cCreated + ")*" + nl
        next
        return createSuccessResult(cOut)

    func viewMemory(cCategory)
        if oLongTermMemory = null
            oLongTermMemory = new LongTermMemory
        ok
        oLongTermMemory.syncMarkdownFile()
        cCategory = trim(cCategory)
        if cCategory = ""
            cMDPath = APP_PATH("ai/memory/MEMORY.md")
            if fexists(cMDPath)
                return createSuccessResult(read(cMDPath))
            ok
            return createSuccessResult(oLongTermMemory.exportMarkdown())
        ok

        # Filter by category
        aAll = oLongTermMemory.getAllMemories()
        aFiltered = []
        for oMem in aAll
            if lower(getValueFromList(oMem, "category", "")) = lower(cCategory)
                aFiltered + oMem
            ok
        next
        if len(aFiltered) = 0
            return createSuccessResult("No memories found in category: '" + cCategory + "'")
        ok
        cOut = "# Memories in category [" + cCategory + "]:" + nl + nl
        for oMem in aFiltered
            cFact = getValueFromList(oMem, "fact", "")
            nImp = getValueFromList(oMem, "importance", 5)
            cCreated = getValueFromList(oMem, "created", "")
            cOut += "- **[" + nImp + "/10]** " + cFact + " *(recorded: " + cCreated + ")*" + nl
        next
        return createSuccessResult(cOut)

    func forgetFact(cKeyword)
        if oLongTermMemory = null
            oLongTermMemory = new LongTermMemory
        ok
        cKeyword = trim(cKeyword)
        if cKeyword = ""
            return createErrorResult("Keyword cannot be empty.")
        ok
        nRemoved = oLongTermMemory.forget(cKeyword)
        oLongTermMemory.syncMarkdownFile()
        if nRemoved > 0
            return createSuccessResult("Removed " + nRemoved + " memory entry/entries matching '" + cKeyword + "'.")
        else
            return createSuccessResult("No memories matched keyword '" + cKeyword + "'.")
        ok

    # ===================================================================
    # Normalize Parameters (Handle Positional vs Associative)
    # ===================================================================
    func normalizeParameters(cToolName, aInParams)
        if type(aInParams) != "LIST" return [] ok
        
        # Find tool definition
        oTool = null
        for oT in aAvailableTools
            if oT.name = cToolName oTool = oT exit ok
        next
        if oTool = null return aInParams ok
        
        # If it's already an associative list (pairs of [key, val]), keep it
        if len(aInParams) > 0 and type(aInParams[1]) = "LIST" and len(aInParams[1]) = 2
            return aInParams
        ok
        
        # Check for flat associative list [key1, val1, key2, val2]
        # (Very common in Ring)
        bIsFlatAssoc = false
        if len(aInParams) >= 2 and (len(aInParams) % 2 = 0)
            # Simple heuristic: is first item a known param name?
            for cPName in oTool.parameters
                if aInParams[1] = cPName
                    bIsFlatAssoc = true
                    exit
                ok
            next
        ok
        if bIsFlatAssoc return aInParams ok

        # If it's positional, convert to associative pairs
        aNew = []
        for i = 1 to len(aInParams)
            if i <= len(oTool.parameters)
                Add(aNew, [oTool.parameters[i], aInParams[i]])
            ok
        next
        return aNew


    # ===================================================================
    # Delegate Task (Sub-Agent Instantiation)
    # ===================================================================
    func delegateTask(cTaskInstruction, nDepth)
        try
            # Recursion Guard
            if nDepth >= 3
                return createErrorResult("DELEGATION ERROR: Maximum nesting depth (3) reached. Recursion halted.")
            ok

            # Ensure SmartAgent is available in the current runtime
            if not isclass("SmartAgent")
                return createErrorResult("Cannot delegate task: SmartAgent class not loaded.")
            ok
            
            # Spin up a completely isolated instance
            oSubAgent = new SmartAgent()
            oSubAgent.init()
            oSubAgent.nAgentDepth = nDepth + 1
            
            # Inherit authorization status for sub-task
            if bAuthorized
                oSubAgent.setSessionAuthorized(true)
            ok
            
            # Disable UI outputs for headless operation to prevent console spam
            oSubAgent.setUIManager(NULL)
            
            # Audit Trail
            cAuditLog = APP_PATH("logs/sub_agents_audit.log")
            ensureDirectoryExists(APP_PATH("logs"))
            cCurrentLog = ""
            if fexists(cAuditLog) cCurrentLog = read(cAuditLog) ok
            write(cAuditLog, cCurrentLog + nl + "[" + date() + " " + time() + "] DEPTH " + nDepth + " TASK: " + cTaskInstruction + nl)
            
            # Inject a system prompt note ensuring the sub-agent knows its role
            cPrefix = "SYSTEM PROTOCOL: You are a SUB-AGENT (Depth: " + (nDepth+1) + "). Your mission is to execute the following specific sub-task in your own isolated memory layer. Output a comprehensive final report when done." + nl + "[SUB-TASK INSTRUCTION]" + nl
            
            see "  [+] Spawning autonomous sub-agent (Depth " + (nDepth+1) + ") for delegated task..." + nl
            oResp = oSubAgent.processRequest(cPrefix + cTaskInstruction, "")
            see "  [-] Sub-agent completed task." + nl
            
            cCurrentLog = ""
            if fexists(cAuditLog) cCurrentLog = read(cAuditLog) ok
            write(cAuditLog, cCurrentLog + "[" + date() + " " + time() + "] DEPTH " + nDepth + " COMPLETED." + nl)            
            if oResp[:success]
                return createSuccessResult("SUB-AGENT REPORT:" + nl + oResp[:message])
            else
                return createErrorResult("SUB-AGENT FAILED: " + oResp[:error])
            ok
            
        catch
            return createErrorResult("Delegation error: " + cCatchError)
        done
        
    func isCoreProtected(cPath)
        if bAuthorized return false ok
        cLower = lower(cPath)
        # Comprehensive protection list: secrets, config, and core agent modules
        aBlacklist = [".env", "api_keys.json", "config/api_keys",
                      "smart_agent.ring", "core_agent.ring", "agent_tools.ring",
                      "ai_client.ring", "context_engine.ring", "security_layer.ring",
                      "loadfiles.ring", "http_client.ring", "mcp_client_manager.ring"]
        for cCore in aBlacklist
            if substr(cLower, cCore) return true ok
        next
        return false

    # ===================================================================
    # MCP Server Connection & Tool Registration
    # ===================================================================
    func connectMCPServer(cServerName, cTransport, cEndpoint, aArgs)
        aMappedTools = []
        if lower(cTransport) = "stdio"
            aMappedTools = oMCPManager.connectStdio(cServerName, cEndpoint, aArgs)
        elseif lower(cTransport) = "http"
            aMappedTools = oMCPManager.connectHttp(cServerName, cEndpoint)
        else
            return false
        ok
        
        if len(aMappedTools) = 0
            see "  [!] No tools found on MCP Server: " + cServerName + nl
            return true
        ok
        
        # Register the tools dynamically
        for oItem in aMappedTools
            oClient = oItem[:client]
            oToolDef = oItem[:toolDef]
            
            cMCPName = getValueFromList(oToolDef, "name", "")
            if cMCPName = "" loop ok
            
            cPrefix = "mcp_" + substr(oClient.name, " ", "_") + "_"
            cFlashName = cPrefix + cMCPName
            
            cDesc = getValueFromList(oToolDef, "description", "")
            
            aParams = []
            oSchema = getValueFromList(oToolDef, "inputSchema", [])
            oProps = getValueFromList(oSchema, "properties", [])
            if type(oProps) = "LIST" and len(oProps) > 0
                # Usually in Ring simplejson, objects are lists of pairs
                if type(oProps[1]) = "LIST" and len(oProps[1]) >= 2
                    for item in oProps
                        cKey = item[1]
                        oProp = item[2]
                        cType = getValueFromList(oProp, "type", "string")
                        cPDesc = getValueFromList(oProp, "description", "")
                        aParams + [cKey, cPDesc, cType]
                    next
                ok
            ok
            
            oNewTool = createToolFull(cFlashName, cDesc, aParams, "mcp_tool")
            addattribute(oNewTool, "is_mcp")
            addattribute(oNewTool, "mcp_client")
            addattribute(oNewTool, "mcp_name")
            oNewTool.is_mcp = true
            oNewTool.mcp_client = oClient
            oNewTool.mcp_name = cMCPName
            
            Add(aAvailableTools, oNewTool)
            see "  [+] Registered MCP Tool: " + cFlashName + nl
        next
        return true
        
    # ===================================================================
    # Auto-Connect to MCP Servers from JSON config
    # ===================================================================
    func autoConnectMCPServers()
        cConfigFile = APP_PATH("config/mcp_servers.json")
        if not fexists(cConfigFile) return false ok
        
        try
            cJsonCode = read(cConfigFile)
            oConfig = json2list(cJsonCode)
            
            if type(oConfig) = "LIST"
                oServers = getValueFromList(oConfig, "mcpServers", [])
                if type(oServers) = "LIST" and len(oServers) > 0
                    if type(oServers[1]) = "LIST" and len(oServers[1]) = 2
                        # Ring associative list format
                        for oServerPair in oServers
                            cServerName = oServerPair[1]
                            oServerConfig = oServerPair[2]
                            
                            # Skip invalid entries (e.g. non-config items)
                            if not islist(oServerConfig) loop ok
                            
                            cCommand = getValueFromList(oServerConfig, "command", "")
                            if cCommand = "" loop ok
                            
                            cTransport = getValueFromList(oServerConfig, "transport", "stdio")
                            
                            see "  [*] Auto-connecting to MCP Server: " + cServerName + "..." + nl
                            if lower(cTransport) = "stdio"
                                aArgs = getValueFromList(oServerConfig, "args", [])
                                if type(aArgs) != "LIST" aArgs = [] ok
                                if connectMCPServer(cServerName, "stdio", cCommand, aArgs)
                                    see "  [+] Connected to " + cServerName + " successfully!" + nl
                                else
                                    see "  [-] Failed to connect to " + cServerName + nl
                                ok
                            elseif lower(cTransport) = "http"
                                cUrl = getValueFromList(oServerConfig, "url", "")
                                if cUrl != ""
                                    if connectMCPServer(cServerName, "http", cUrl, [])
                                        see "  [+] Connected to " + cServerName + " successfully!" + nl
                                    else
                                        see "  [-] Failed to connect to " + cServerName + nl
                                    ok
                                ok
                            ok
                        next
                    ok
                ok
            ok
        catch
            see "  [-] Error loading MCP Servers config: " + cCatchError + nl
        done
        return true
        
    # ===================================================================
    # MCP Servers Config Management (Unified API)
    # ===================================================================
    func getMCPServers()
        cConfigFile = APP_PATH("config/mcp_servers.json")
        aRes = []
        if fexists(cConfigFile)
            try
                oConfig = json2list(read(cConfigFile))
                oServersList = getValueFromList(oConfig, "mcpServers", [])
                if type(oServersList) = "LIST" and len(oServersList) > 0 and type(oServersList[1]) = "LIST"
                    for oServerPair in oServersList
                        Add(aRes, [ oServerPair[1], getValueFromList(oServerPair[2], "transport", "stdio"), oServerPair[2] ])
                    next
                ok
            catch done
        ok
        return aRes

    func addMCPServerConfig(cName, cTrans, cCmdUrl)
        cConfigFile = APP_PATH("config/mcp_servers.json")
        oConfig = [["mcpServers", []]]
        if fexists(cConfigFile)
            try
                oConfig = json2list(read(cConfigFile))
            catch done
        ok
        
        oServersList = getValueFromList(oConfig, "mcpServers", [])
        if type(oServersList) != "LIST" or len(oServersList) = 0 or type(oServersList[1]) != "LIST"
            oServersList = []
            oConfig = [["mcpServers", oServersList]]
        ok
        
        oNewServer = []
        Add(oNewServer, ["transport", cTrans])
        if cTrans = "stdio"
            aParts = split(cCmdUrl, " ")
            if len(aParts) > 0
                Add(oNewServer, ["command", aParts[1]])
                aArgs = []
                for i = 2 to len(aParts) Add(aArgs, aParts[i]) next
                Add(oNewServer, ["args", aArgs])
            ok
        else
            Add(oNewServer, ["url", cCmdUrl])
        ok
        
        for i = 1 to len(oServersList)
            if type(oServersList[i]) = "LIST" and oServersList[i][1] = cName
                del(oServersList, i)
                exit
            ok
        next
        
        Add(oServersList, [cName, oNewServer])
        write(cConfigFile, jsonEncodeValue([["mcpServers", oServersList]]))
        
        # Connect dynamically
        if cTrans = "stdio"
            return connectMCPServer("stdio", getValueFromList(oNewServer, "command", ""), getValueFromList(oNewServer, "args", []))
        else
            return connectMCPServer("http", cCmdUrl, [])
        ok

    func removeMCPServerConfig(cName)
        cConfigFile = APP_PATH("config/mcp_servers.json")
        if fexists(cConfigFile)
            try
                oConfig = json2list(read(cConfigFile))
                oServersList = getValueFromList(oConfig, "mcpServers", [])
                if type(oServersList) = "LIST" and len(oServersList) > 0 and type(oServersList[1]) = "LIST"
                    for i = 1 to len(oServersList)
                        if type(oServersList[i]) = "LIST" and oServersList[i][1] = cName
                            del(oServersList, i)
                            write(cConfigFile, jsonEncodeValue([["mcpServers", oServersList]]))
                            return true
                        ok
                    next
                ok
            catch done
        ok
        return false

    # ===================================================================
    # Filtered Function Declarations (Gemini)
    # ===================================================================
    func getFilteredGeminiJSON(aAllowedTools)
        cJSON = "["
        bFirst = true
        for oTool in aAvailableTools
            bIsMCP = false
            try bIsMCP = oTool.is_mcp catch bIsMCP = false done
            
            if find(aAllowedTools, oTool.name) = 0 and not bIsMCP loop ok
            
            if not bFirst cJSON += "," ok
            bFirst = false
            
            cJSON += '{"name":"' + oTool.name + '",'
            cJSON += '"description":"' + oTool.description + '",'
            cJSON += '"parameters":{"type":"object","properties":{'
            
            bFirstProp = true
            for aDef in oTool.paramDescriptions
                if not bFirstProp cJSON += "," ok
                bFirstProp = false
                cJSON += '"' + aDef[1] + '":{"type":"' + aDef[3] + '","description":"' + aDef[2] + '"}'
            next
            
            cJSON += '},"required":['
            bFirstReq = true
            for aDef in oTool.paramDescriptions
                if not bFirstReq cJSON += "," ok
                bFirstReq = false
                cJSON += '"' + aDef[1] + '"'
            next
            cJSON += "]}}"
        next
        cJSON += "]"
        return cJSON

    # ===================================================================
    # Filtered Tools (OpenRouter/OpenAI)
    # ===================================================================
    func getFilteredOpenAIJSON(aAllowedTools)
        cJSON = "["
        bFirst = true
        for oTool in aAvailableTools
            bIsMCP = false
            try bIsMCP = oTool.is_mcp catch bIsMCP = false done
            
            if find(aAllowedTools, oTool.name) = 0 and not bIsMCP loop ok
            
            if not bFirst cJSON += "," ok
            bFirst = false
            
            cJSON += '{"type":"function","function":{'
            cJSON += '"name":"' + oTool.name + '",'
            cJSON += '"description":"' + oTool.description + '",'
            cJSON += '"parameters":{"type":"object","properties":{'
            
            bFirstProp = true
            for aDef in oTool.paramDescriptions
                if not bFirstProp cJSON += "," ok
                bFirstProp = false
                cJSON += '"' + aDef[1] + '":{"type":"' + aDef[3] + '","description":"' + aDef[2] + '"}'
            next
            
            cJSON += '},"required":['
            bFirstReq = true
            for aDef in oTool.paramDescriptions
                if not bFirstReq cJSON += "," ok
                bFirstReq = false
                cJSON += '"' + aDef[1] + '"'
            next
            cJSON += "]}}}"
        next
        cJSON += "]"
        return cJSON
        
class stdclass
    name 
    description
    parameters
    paramDescriptions   # List of [paramName, paramDescription, paramType] per param
    category
