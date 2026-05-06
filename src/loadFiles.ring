# ===================================================================
# load all files
# ===================================================================


load "stdlib.ring"
load "jsonlib.ring"
load "libcurl.ring"

load "logger.ring"
load "utils.ring"
load "security_layer.ring"
load "telemetry.ring"
load "long_term_memory.ring"
load "localization.ring"
load "theme_manager.ring"
load "ui_manager.ring"
load "smart_agent.ring"
load "core_agent.ring"

load "ai_client.ring"
load "context_engine.ring"
load "context_intelligence.ring"
load "reflection_engine.ring"
load "agent_state_machine.ring"
load "http_client.ring"

# Domain tool modules (standalone functions used by AgentTools dispatcher)
load "tools/file_tools.ring"
load "tools/code_tools.ring"
load "tools/project_tools.ring"
load "tools/system_tools.ring"

load "agent_tools.ring"
load "tool_selector.ring"