# 🤝 Contributing to FLASH AI

We welcome contributions from the community to help make **FLASH AI** the world's most advanced autonomous system built in the **Ring language**.

---

## 🏗️ Getting Started

1. **Fork the Repository:** Create a copy of the project on your own account.
2. **Setup Your Environment:** Ensure you have **Ring 1.18+** installed along with `guilib`, `curllib`, and `jsonlib`.
3. **Configure API Keys:** Add your development keys to `config/api_keys.json`.

---

## 📜 Coding Guidelines

Since FLASH AI is built in **Ring**, we follow these principles:

- **Modular Design:** Keep the `CoreAgent`, `SmartAgent`, and `AgentTools` separate.
- **Error Handling:** Always wrap API calls and file operations in `try-catch` blocks or explicit checks.
- **Bilingual Focus:** Ensure any new UI elements support both Arabic (RTL) and English (LTR).

### 🛠️ Adding New Tools
To add a new autonomous tool:
1. Open `src/agent_tools.ring`.
2. Define your tool in the `aTools` list.
3. Implement the internal execution logic in the `executeTool` method.
4. Ensure the tool returns a clear, JSON-parsable result.

---

## 🧪 Testing

We value stability. Before submitting a Pull Request:
- **UI Check:** Ensure the GUI launches and scales correctly on high-DPI screens.
- **Agentic Loop Check:** Verify that multiple reasoning steps correctly sum up tokens.
- **CLI Check:** Ensure the terminal version still functions for lightweight tasks.

---

## 📬 Submitting Changes

1. **Create a Branch:** `git checkout -b feature/amazing-tool`
2. **Commit Your Changes:** `git commit -m 'Add amazing new tool'`
3. **Push to Your Branch:** `git push origin feature/amazing-tool`
4. **Open a Pull Request:** Describe your changes in detail.

---

## ⚖️ Code of Conduct

Help us maintain a professional and welcoming environment for everyone. Respect all contributors and focus on building sovereign intelligence together.

---
**Senior Systems Architect v2.5**
*Developed with sovereign AI architecture principles.*
