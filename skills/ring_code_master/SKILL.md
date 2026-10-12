---
name: ring_code_master
description: Deep expertise in the Ring programming language. Use this skill whenever writing, analyzing, refactoring, or optimizing Ring source code.
---

# Ring Code Master Skill

## Purpose
Provides authoritative guidelines, idioms, and best practices for writing clean, efficient, and robust code in the Ring programming language.

## Core Language Rules & Best Practices

### 1. File Structure & Declarations
- Always place `load "stdlib.ring"` at the top if using standard library functions like `split()`, `trim()`, `substr()`, or file utilities.
- Functions are declared with `func <name>(<params>)` or `func <name> { ... }`.
- In class methods, class attributes can be referenced directly by name without `self.` (though `self.` is allowed when resolving shadowing).

### 2. Lists & Multi-Dimensional Data
- Ring lists are **1-indexed** (`list[1]` is the first element).
- To append an item, use the `+` operator: `myList + newItem`.
- Key-Value pairs in Ring are standard lists of pairs: `[["key", "value"], ["id", 101]]`.
- Always check list bounds before indexing: `if len(myList) >= index ...`.

### 3. Strings & Conversions
- String concatenation is done with `+`: `"Hello " + cName`.
- Numbers are converted to strings using concatenation: `"" + nNumber` or `string(nNumber)`.
- Strings are converted to numbers using: `0 + cString` or `number(cString)`.
- Use `lower(cStr)` or `upper(cStr)` for case-insensitive comparisons.

### 4. Error Handling & Subprocesses
- Use `try ... catch ... done` around operations that may fail (such as file I/O or `eval`).
- The error message inside catch is accessible via the special variable `cCatchError`.
- For running compiler syntax verification: use `safeSystem("ring -c <file>")` to catch syntax errors without terminating the agent process.

### 5. Memory Management
- Ring automatically manages memory using reference counting.
- When working with large files, read them once into a variable or process in chunks.
