# 🛡️ FLASH AI Security Policy

At **FLASH AI**, security is a core priority. We take extensive measures to ensure your data and API credentials remain protected at all times.

---

## 🔒 Current Protections

### 1. Permission-Based Control (Authorization Mode)
FLASH AI operates in **Read-Only** mode by default.
- It can read and analyze files but cannot **write, modify, or delete** anything unless you explicitly click the "Full Permissions" checkbox in the GUI or type `/authorize` in the CLI.

### 2. Guarded System Paths
- The system includes a **Path Normalizer** that prevents the AI from using `..` (directory traversal) to access files outside the project root.
- All file operations are restricted to the local project workspace.

### 3. Masking Sensitive Files
- FLASH AI is specifically instructed to **NEVER** output or leak the contents of:
    - `.env` files
    - `config/api_keys.json`
    - Any other credential files specified in the configuration.

### 4. Code Injection Mitigation
- The script-based tool execution in `AgentTools.executeTool` uses a sandboxed-like approach by parsing function names and arguments before actual execution.
- System-level `ossystem()` calls are restricted to pre-defined, safe commands.

---

## 🗃️ Reporting Vulnerabilities

If you discover a security vulnerability in FLASH AI, please report it immediately:
1. **GitHub Issues:** Open an issue with the "Security" label if it doesn't leak private details.
2. **Direct Contact:** Send a detailed report to the maintainers if the vulnerability is severe.

Please include:
- A description of the vulnerability.
- Steps to reproduce the issue.
- Potential impact on the system.

---

## ⚠️ Responsible Use

While FLASH AI is designed for autonomy, we recommend:
- **Do not** grant Full Permissions on sensitive production systems without oversight.
- **Do not** provide the AI with keys that have uncontrolled billing limits.
- **Review and Audit** all changes made by the AI before committing them to your main branch.

---
**Senior Systems Architect v2.5**
*Developed with sovereign AI architecture principles.*
