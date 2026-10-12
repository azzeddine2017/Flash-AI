# 🚀 FLASH AI v3.0 User Guide - The Sovereign Intelligence

![FLASH AI Banner](images/banner.png)

## 🌟 Introduction
Welcome to **FLASH AI**, the high-level intelligent system built entirely in the **Ring language**. This isn't just a chatbot; it's a **Senior Systems Architect** capable of executing complex tasks, solving programming problems, and evolving autonomously through self-generated tools.

---

## 🎨 Exploring the Premium GUI

The graphical interface is designed for speed, elegance, and professional use:

### 1. Professional Message Submission (Enter-to-Send)
Modeled after world-class chat applications:
- **Enter Key:** Sends your message immediately.
- **Shift + Enter:** Adds a new line in the input box.
- **Ctrl + Enter:** Alternative shortcut for quick sending.

### 2. Live Cumulative Token Counter
- **Precise Calculation:** FLASH AI accurately sums up all tokens (words) consumed during "Reasoning" and "Tool Calls" at each internal step.
- The total session cost is displayed at the top right of the GUI, ensuring full visibility into resource usage.

### 3. Styled Chat Bubbles & Reasoning Blocks
- **Chat Bubbles:** Featuring a modern dark-mode aesthetic with vibrant blue gradients for your messages and sleek dark-card styling for the AI responses.
- **Reasoning Blocks:** FLASH AI displays its internal "Thinking" steps in dedicated boxes, allowing you to follow the system's logic before it executes a solution.

### 4. Language Toggling
- A dedicated button in the sidebar switches the entire interface (AR/EN) and automatically adjusts text direction (RTL/LTR).

---

## 🏗️ Getting Started

### Prerequisites
1. **Ring Language 1.18+** installed on your system.
2. An **API Key** from Gemini, OpenAI, or Claude.
3. Place your key in `config/api_keys.json`.

### Execution (GUI - Recommended)
Open your terminal in the project directory and run:
```bash
ring gui_main.ring
```

### Execution (CLI - Terminal)
If you prefer a lightweight terminal experience:
```bash
ring main.ring
```

---

## 🛡️ Permissions & Security

**FLASH AI is read-biased, not locked read-only.** Exploration tools (`list_files`, `read_file`, `grep_search`, `analyze_project`, `git_status`, running Ring code) work without extra prompts. **Modification tools** (`write_file`, `replace_file_content`, `delete_file`, `execute_command`, `git_commit`, `evolve_new_tool`) require explicit confirmation the first time they are used in a session (or the `/authorize` flag / "Full Permissions" GUI checkbox to grant session-wide approval). This protects your files while keeping the agent useful. If the Security Layer blocks a core file, it will ask you to type `/authorize`.

> In `/plan` mode the agent is strictly READ-ONLY and will stop before any writing tool. In `/auto` mode it plans and executes iteratively.

---

## 🔁 Session & History Management
- **New Session:** Clear current context and start fresh on a new topic.
- **Save Chat:** Export your conversation as (JSON, Text, or Markdown).
- **Session History:** Access previous chats from the sidebar to continue older tasks.

---

## 🛠️ Pro Tips
- **Massive Code Paste:** You can paste large code blocks without fear of accidental sending; FLASH AI handles long-form input gracefully.
- **Dynamic File Analysis:** Ask FLASH AI to "analyze file.ring", and it will autonomously search for it, read it, and provide a deep summary.

---
**Developed by FLASH AI - Senior Systems Architect v3.0**
*Empowering developers through sovereign autonomous intelligence.*
