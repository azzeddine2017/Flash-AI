
func context_summarizer() {
    files = list_files(".")
    return "The project contains " + len(files) + " files. The basic structure is based on Ring Language. The main components include core_agent.ring, main.ring, and ui_manager.ring."
}
