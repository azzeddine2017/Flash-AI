---
name: ring_test_suite
description: Comprehensive testing workflows and assertions for Ring using the ringtest framework (from G:\RingProject\ringtest). Use when writing, running, structuring, or debugging unit/integration tests, assertions (describe/it/expect), mocks, benchmarks, and CI/CD test reports in Ring projects.
---

# Ring Test Suite (`ringtest`) Skill

## Overview
This skill guides FLASH AI in authoring, executing, and structuring unit tests, integration tests, and benchmarks for Ring projects using **ringtest** (v1.2.0+), a modern BDD/TDD testing framework and runner located at `G:\RingProject\ringtest`.

---

## Core Testing Workflow

### 1. Test File Naming & Location
- Test files must reside in `./tests` (or subdirectories).
- Naming convention: `*_test.ring` or `test_*.ring` (e.g. `tests/utils_test.ring`, `tests/test_agent.ring`).
- **No `load` required when running under `ringtest`**: The test runner automatically injects `describe`, `it`, `test`, `expect`, `context`, etc.
- **Ordering Rule in Ring**: `describe(...)` calls must always precede any top-level `func` or `class` blocks in the file. Ring ignores top-level code that follows top-level function declarations.

### 2. Basic BDD Test Structure
```ring
describe("String Manipulation Module", func {

    it("should concatenate strings properly", func {
        s = "Hello " + "World"
        expect(s).toBe("Hello World")
        expect(len(s)).toBe(11)
    })

    test("should check substring containment", func {
        expect("Flash AI Agent").toContain("Flash")
        expect("Ring Language").toStartWith("Ring")
        expect("archive.zip").toEndWith(".zip")
    })

    it("should catch runtime errors cleanly", func {
        expect("1 / 0").toThrowError("Zero")
    })
})
```

---

## Assertions Reference Table

| Assertion | Description | Example |
|---|---|---|
| `.toBe(val)` | Strict equality | `expect(2 + 2).toBe(4)` |
| `.not_().toBe(val)` | Inverted equality | `expect(5).not_().toBe(10)` |
| `.toEqual(list)` | Deep list/structure comparison | `expect([1, [2]]).toEqual([1, [2]])` |
| `.toBeTruthy()` | Not null, false, 0, or empty | `expect("hello").toBeTruthy()` |
| `.toBeFalsy()` | Is null, false, 0, or empty | `expect("").toBeFalsy()` |
| `.toBeNull()` | Is strictly NULL | `expect(NULL).toBeNull()` |
| `.toBeNotNull()` | Is not NULL | `expect("data").toBeNotNull()` |
| `.toBeString()` | Type check string | `expect("text").toBeString()` |
| `.toBeNumber()` | Type check number | `expect(42).toBeNumber()` |
| `.toBeList()` | Type check list | `expect([1, 2, 3]).toBeList()` |
| `.toBeObject()` | Type check object | `expect(new MyClass).toBeObject()` |
| `.toContain(item)` | Substring or list inclusion | `expect(["a", "b"]).toContain("a")` |
| `.toBeGreaterThan(n)` | Numeric strictly greater | `expect(10).toBeGreaterThan(5)` |
| `.toBeGreaterThanOrEqual(n)` | Numeric greater or equal | `expect(10).toBeGreaterThanOrEqual(10)` |
| `.toBeLessThan(n)` | Numeric strictly less | `expect(5).toBeLessThan(10)` |
| `.toBeLessThanOrEqual(n)` | Numeric less or equal | `expect(5).toBeLessThanOrEqual(5)` |
| `.toBeBetween(min, max)` | Numeric range check | `expect(50).toBeBetween(1, 100)` |
| `.toBeCloseTo(expected, delta)` | Floating point approx | `expect(0.1 + 0.2).toBeCloseTo(0.3, 0.001)` |
| `.toStartWith(prefix)` | String prefix check | `expect("RingLang").toStartWith("Ring")` |
| `.toEndWith(suffix)` | String suffix check | `expect("doc.pdf").toEndWith(".pdf")` |
| `.toBeSorted()` | Ascending order check | `expect([1, 2, 3]).toBeSorted()` |
| `.toBeEmpty()` | Empty string or list | `expect("").toBeEmpty()` |
| `.toHaveLength(n)` | Length comparison | `expect("flash").toHaveLength(5)` |
| `.toThrow()` | Asserts evaluated string throws | `expect("1 / 0").toThrow()` |
| `.toThrowError(substr)` | Asserts error message matches | `expect("1 / 0").toThrowError("Zero")` |
| `.notToThrow()` | Asserts code executes safely | `expect("x = 10").notToThrow()` |

---

## Parameterized / Data-Driven Tests (`itEach`)

Execute identical assertions over matrix datasets:
```ring
describe("Math Matrix", func {
    itEach([[1, 2, 3], [10, 20, 30], [5, 5, 10]], "adds %1 + %2 = %3", func a, b, expected {
        expect(a + b).toBe(expected)
    })

    itEach(["item1", "item2", "item3"], "checks '%1' length", func item {
        expect(len(item)).toBe(5)
    })
})
```

---

## Lifecycle Hooks & Shared Context

Top-level variables in a test file are isolated from `it()` blocks. Use the Context API:
```ring
describe("Database Operations", func {

    beforeAll(func {
        ctxSet("conn", "active")
        ctxSet("queries", 0)
    })

    beforeEach(func {
        ctxIncr("queries")
    })

    afterEach(func {
        # Teardown per test
    })

    afterAll(func {
        ctxSet("conn", "closed")
    })

    it("should have active connection", func {
        expect(ctxGet("conn")).toBe("active")
        expect(ctxGet("queries")).toBeGreaterThan(0)
    })
})
```

---

## Skip, Todo & Expected Failures
```ring
describe("WIP Features", func {
    itSkip("payment gateway API", "Waiting for API keys")
    itTodo("implement OAuth2 refresh tokens")
    itFailing("known edge case bug #42", func {
        expect(10).toBe(999)
    }, "Known parser bug")
})
```

---

## Mocking & Spying
```ring
# Register a mock function
m = mock("networkFetch", NULL)
m.setReturn('{"status": "ok"}')

# Execute calls
m.doCall()
m.doCall()

# Assert mock interactions
expect(m).toHaveBeenCalled()
expect(m).toHaveBeenCalledTimes(2)

# Restore original function
restore("networkFetch")
```

---

## High-Precision Benchmarks & Performance
```ring
describe("Performance Benchmarking", func {
    it("measures execution throughput", func {
        res = benchmark("List Appending", 1000, func {
            aList = []
            for i = 1 to 100
                add(aList, i)
            next
        })
        expect(res[:opsPerSec]).toBeGreaterThan(500)
    })

    it("compares two approaches side-by-side", func {
        benchmarkCompare(
            "Operator +", func { a = [] a + 1 },
            "Add Function", func { a = [] add(a, 1) },
            1000
        )
    })
})
```

---

## CLI Execution & CI/CD Reports

Execute from the project root:
```bash
# 1. Run all tests in ./tests
ringtest

# 2. Run specific test file or directory
ringtest tests/utils_test.ring
ringtest tests/

# 3. Filter tests by name or description
ringtest --filter=math

# 4. Generate Interactive Dark-Mode HTML Report
ringtest --html
# Outputs to reports/test-report.html

# 5. Generate JUnit XML Report for CI/CD
ringtest --junit
# Outputs to reports/test-report.xml

# 6. Watch Mode (Auto re-run on file changes)
ringtest --watch
```
