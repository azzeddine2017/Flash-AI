# 🚀 FLASH AI v2.5 User Guide - The Sovereign Intelligence

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

By default, FLASH AI runs in **Read-Only** mode to protect your files from unintended changes.
- **To Grant Full Permissions (Authorize):**
    - **GUI:** Toggle the **"Full Permissions"** checkbox in the sidebar.
    - **CLI:** Type `/authorize` during the chat.
- Without this authorization, FLASH AI can only read/analyze your code but cannot write, modify, or delete files.

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
**Developed by FLASH AI - Senior Systems Architect v2.5**
*Empowering developers through sovereign autonomous intelligence.*
