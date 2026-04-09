# ===================================================================
# Adaptive Tool Selector - Optimized for Token Conservation
# ===================================================================

class AdaptiveToolSelector

    # Core tools that give the agent its "eyes and ears" (Always included)
    aCoreTools = ["read_file", "list_files", "grep_search", "search_in_files", 
                  "execute_command", "evolve_new_tool", "delegate_task"]

    func getRelevantTools(cRequestType)
        aSelected = aCoreTools

        switch cRequestType
            on "file_operation"
                aSelected + "write_file"
                aSelected + "delete_file"
                aSelected + "replace_file_content"
                aSelected + "create_directory"
                
            on "code_analysis"
                aSelected + "run_ring_code"
                aSelected + "analyze_code"
                aSelected + "format_code"
                aSelected + "automated_test_suite"
                aSelected + "code_refactor_assistant"
                
            on "project_management"
                aSelected + "create_project"
                aSelected + "analyze_project"
                aSelected + "git_init"
                aSelected + "git_status"
                aSelected + "git_add"
                aSelected + "git_commit"
                aSelected + "dependency_graph_generator"
                
			on "web_operation"
                aSelected + "read_url"
                aSelected + "get_bitcoin"

            on "system_operation"
                aSelected + "execute_command"
                
            on "self_evolution"
                aSelected + "evolve_new_tool"
                aSelected + "analyze_code"
                
            on "general_chat"
                # نرسل فقط الأدوات التي تسمح له بالاستكشاف دون تعديل
                aSelected + "context_summarizer"
                aSelected + "system_health_check"
        off
        
        return aSelected