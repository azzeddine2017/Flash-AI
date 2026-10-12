---
name: code_refactoring
description: Systematic workflow for safely refactoring, modularizing, and cleaning code without regressions. Use when rewriting or improving existing components.
---

# Code Refactoring Skill

## Purpose
Establishes a zero-regression, disciplined process for transforming complex or legacy code into clean, modular, maintainable software.

## Refactoring Protocol

1. **Understand Before Touching**:
   - Read the existing file in full.
   - Identify all callers and dependencies across the codebase (e.g. using `grep_search`).

2. **Surgical Precision**:
   - Avoid rewriting entire files when changing a single function. Use surgical replacement (`replace_file_content`).
   - Preserve existing function signatures and comment headers.

3. **Verify at Every Step**:
   - After modifying Ring source files, run the compiler syntax check (`ring -c <file>`) to ensure no missing braces, brackets, or syntax errors.
   - Run existing unit tests in `tests/`.

4. **Modular Separation**:
   - Keep files focused on a single responsibility.
   - Move large sub-components into dedicated modules in `src/`.
