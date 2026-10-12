# ===================================================================
# Adaptive Tool Selector - Unlocked for Autonomous Sovereignty
# ===================================================================

class AdaptiveToolSelector

    # Complete autonomous toolkit giving the agent full visibility and capabilities
    aFullArsenal = [
        "read_file", "write_file", "replace_file_content", "delete_file",
        "list_files", "create_directory", "grep_search", "search_in_files",
        "run_ring_code", "analyze_code", "format_code",
        "create_project", "analyze_project",
        "git_init", "git_status", "git_add", "git_commit",
        "execute_command", "read_url",
        "evolve_new_tool", "delegate_task",
        "list_skills", "activate_skill", "save_skill", "delete_skill",
        "remember_fact", "recall_memory", "view_memory", "forget_fact"
    ]

    func getRelevantTools(cRequestType)
        # A true sovereign autonomous agent decides which tool to use
        # based on context and reasoning, without artificial tool stripping.
        return aFullArsenal