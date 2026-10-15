---
name: ring_test_suite
description: إطار عمل اختبارات البرمجيات ووحدات الفحص (Test Suite) للغة Ring، المستوحى من G:\RingProject\ringtest، لإدارة وتشغيل اختبارات الأكواد والتحقق من سلامتها.
---

# Ring Test Suite (ringtest) Skill

## Overview
This skill provides guidelines, frameworks, and patterns for building, executing, and managing comprehensive Unit and Integration Test Suites in Ring, inspired by `G:\RingProject\ringtest`.

## Key Components
1. **Assertion Framework**: Functions to assert equality, true/false, null checks, and exception/error handling.
2. **Test Runner**: Automated script to discover test files (`test_*.ring`), execute them in isolation, and report success/failure counts.
3. **Test Reporting**: Detailed console or log output showing passed/failed tests with execution times.

## Example Unit Test Structure in Ring (`tests/test_example.ring`):
```ring
# Ring Unit Test Example
func test_addition()
    result = 2 + 3
    if result = 5
        see "[PASS] test_addition\n"
    else
        see "[FAIL] test_addition: expected 5, got " + result + "\n"
    ok

func main()
    see "Running Test Suite...\n"
    test_addition()
    see "Test Suite Completed.\n"

main()
```

## Best Practices
- Keep test files prefixed with `test_`.
- Run tests regularly using Ring interpreter (`ring test_file.ring`).
- Use assertions to ensure high code coverage and regression prevention.
