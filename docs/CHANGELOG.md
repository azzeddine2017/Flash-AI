# 🚀 FLASH AI v3.0 Changelog

All notable changes to this project will be documented in this file.

---

## [3.0.0] - April 2026

### ✨ INTELLIGENCE LAYER & DETERMINISTIC FSM (Architecture upgrades)
- **⚙️ Deterministic Formal State Machine:** Ripped out the chaotic `while` loop within `SmartAgent` and successfully integrated `agent_state_machine.ring`. The core executor now strictly navigates between formal states (`AGENT_PLANNING`, `AGENT_EXEC_TOOL`, `AGENT_REFLECTING`).
- **🧠 Context Intelligence Subsystem:** Completely replaced standard chronological string manipulation for conversation memory with an **importance-weighted contextual scorer**. Tool logs are aggressively truncated, while user requests and error notes are preserved.
- **🔄 Reflection Engine:** Added a self-healing protocol that automatically hooks onto failed Tool operations. Instead of looping blindly onto API errors, it provides localized LLM diagnostic instructions ("Target substring mismatch, try read_file first") without User intervention.
- **🛡️ Rate Limits & Backoff Metrics:** Replaced arbitrary retry sleeps with adaptive exponential backoffs integrated directly into the `retryWithBackoff()` global utility.
- **🔪 Architectural Decoupling:** Segmented the massive 350-line `sendToAI` monolith inside `SmartAgent` into elegant, single-concern dispatch routines and helper pipelines.

---

## [2.6.0] - April 2026

### ✨ CORE UPGRADES (Architecture & UX)
- **🌍 Dynamic Localization:** Implemented a new `Localization` module replacing hardcoded language strings, simplifying translation expansion across UI elements.
- **🎨 Dynamic Theming System:** Added a new `ThemeManager` supporting various color palettes (deepagents, hacker, light). Users can switch themes on the fly using `/theme <name>`.
- **✍️ Multi-line Interactive Editor:** Added `/multi` command for a native, distraction-free multiline writing mode inside the CLI, enabling easier drafting of complex prompts without accidental execution.
- **✨ Animated Loading & Markdown Highlights:** Upgraded the terminal display with syntax highlighting for code blocks (` ``` `) and an improved visual feedback loop during intensive operations.
- **⚡ Advanced Cursor Redrawing:** Overhauled terminal input redraw logic using strict ANSI escape codes for flicker-free rapid line updates, greatly increasing speed while eliminating word-wrapping glitches on resize or backspace.

---

## [2.5.0] - April 2026

### ✨ CORE UPGRADES (Architecture)
- **🧠 Cumulative Token Tracking:** The agentic reasoning loop in `SmartAgent` now correctly sums all internal thought and tool steps (`promptTokenCount` + `candidatesTokenCount`) before returning the final response. Users now see the total true cost of a multi-step session.
- **Robust JSON Parsing:** The `AIClient` now auto-detects if Gemini JSON keys are colon-prefixed or not, solving the "0 tokens" display issue on different environment builds.
- **Smart Path Normalizer:** Improved `AgentTools` to avoid directory traversal and ensure all file modifications stay within the project root.

### 🎨 PREMIUM GUI (Experience)
- **Modern Aesthetics:** Added CSS-style gradients, smooth chat bubbles, and dedicated "Reasoning" blocks for better UX.
- **GUI Enter-to-Send:** Attached `qShortcut` directly to `oInput` with `Qt_WidgetShortcut` context. This ensures that pressing `Return` sends the message even when the input box is focused, while `Shift+Return` allows for manual newlines.
- **Auto-Scroll:** UI now automatically scrolls to the latest message or reasoning block during the agentic loop.
- **Multilingual Support:** One-click toggle between Arabic and English interfaces with full RTL/LTR support.

### 🔧 TECHNICAL FIXES
- **Logger Directory Warnings:** Silenced the `mkdir` "directory already exists" warning on Windows by adding `2>nul` to the command.
- **JSON Key Alignment:** Updated the `getValueFromList` utility to handle both string keys and colon-prefixed string keys (`:key`) for better interoperability with Ring's `jsonlib`.
- **Improved Tool Calling:** Refined the regex for tool extraction to better handle nested arguments and multiline strings.

### 🛡️ SECURITY & SAFETY
- Added further protection for the `.env` and `api_keys.json` files to prevent AI from accidentally reading or leaking them in chat.
- Defined a **Read-Only** default mode that requires explicit user "Authorization" for destructive tools.

---

## [2.0.0] - March 2026

### ✨ Added
- Initial **Graphical User Interface (GUI)** using `guilib`.
- Sidebar for session history and persistence.
- Export formats: JSON, Text, Markdown.
- Basic Toolset (28 tools).

---
**Senior Systems Architect v2.5**
*Developed with sovereign AI architecture principles.*
