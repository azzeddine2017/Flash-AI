# ===================================================================
# FLASH AI - Test Suite: Utilities Module
# Tests all shared functions in utils.ring
# ===================================================================

load "stdlib.ring"
load "src/utils.ring"

nPass = 0
nFail = 0
nTotal = 0

func main {
    see "========================================" + nl
    see "  FLASH AI Test Suite - Utils Module" + nl
    see "========================================" + nl + nl

    # --- JSON Escape ---
    testCase("jsonEscapeStr: basic string",
        jsonEscapeStr("hello"), "hello")
    testCase("jsonEscapeStr: quotes",
        jsonEscapeStr('say "hi"'), 'say ' + char(92) + '"hi' + char(92) + '"')
    testCase("jsonEscapeStr: newline",
        jsonEscapeStr("a" + nl + "b"), "a" + char(92) + "nb")
    testCase("jsonEscapeStr: empty string",
        jsonEscapeStr(""), "")
    testCase("jsonEscapeStr: non-string returns empty",
        jsonEscapeStr(123), "")

    # --- JSON Encode ---
    testCase("jsonEncodeValue: number",
        jsonEncodeValue(42), "42")
    testCase("jsonEncodeValue: string",
        jsonEncodeValue("test"), '"test"')
    testCase("jsonEncodeValue: null list becomes []",
        jsonEncodeValue([]), "[]")
    testCase("jsonEncodeValue: array",
        jsonEncodeValue([1, 2, 3]), "[1,2,3]")
    testCase("jsonEncodeValue: object",
        jsonEncodeValue([["name", "flash"], ["version", "2.0"]]),
        '{"name":"flash","version":"2.0"}')

    # --- getValueFromList ---
    aTestList = [["name", "FLASH"], ["version", "2.0"], ["debug", false]]
    testCase("getValueFromList: existing key",
        getValueFromList(aTestList, "name", ""), "FLASH")
    testCase("getValueFromList: missing key returns default",
        getValueFromList(aTestList, "missing", "default"), "default")
    testCase("getValueFromList: non-list returns default",
        getValueFromList("not a list", "key", "default"), "default")

    # --- generateUniqueId ---
    cId1 = generateUniqueId()
    cId2 = generateUniqueId()
    testCase("generateUniqueId: length is 12",
        len(cId1), 12)
    testCase("generateUniqueId: is a string",
        type(cId1), "STRING")
    testCondition("generateUniqueId: two IDs differ",
        cId1 != cId2)

    # --- sanitizeInput ---
    testCase("sanitizeInput: normal text unchanged",
        sanitizeInput("hello world"), "hello world")
    testCase("sanitizeInput: removes pipe",
        sanitizeInput("hello | world"), "hello  world")
    testCase("sanitizeInput: removes semicolons",
        sanitizeInput("cmd; rm -rf"), "cmd rm -rf")
    testCase("sanitizeInput: non-string returns empty",
        sanitizeInput(123), "")

    # --- isPathSafeCheck ---
    testCondition("isPathSafeCheck: relative path is safe",
        isPathSafeCheck("src/main.ring"))
    testCondition("isPathSafeCheck: .. is NOT safe",
        not isPathSafeCheck("../../etc/passwd"))

    # --- isSensitiveToolCheck ---
    testCondition("isSensitiveToolCheck: write_file is sensitive",
        isSensitiveToolCheck("write_file"))
    testCondition("isSensitiveToolCheck: read_file is NOT sensitive",
        not isSensitiveToolCheck("read_file"))
    testCondition("isSensitiveToolCheck: execute_command is sensitive",
        isSensitiveToolCheck("execute_command"))

    # --- isPathToolCheck ---
    testCondition("isPathToolCheck: read_file is path tool",
        isPathToolCheck("read_file"))
    testCondition("isPathToolCheck: git_init is NOT path tool",
        not isPathToolCheck("git_init"))

    # --- countSubstring ---
    testCase("countSubstring: basic count",
        countSubstring("aabbaabb", "aa"), 2)
    testCase("countSubstring: no match",
        countSubstring("hello", "xyz"), 0)
    testCase("countSubstring: single char",
        countSubstring("banana", "a"), 3)

    # --- hasArabicText ---
    testCondition("hasArabicText: English returns false",
        not hasArabicText("hello world"))

    # --- isCommandBlacklisted ---
    testCondition("isCommandBlacklisted: format is blocked",
        isCommandBlacklisted("format C:"))
    testCondition("isCommandBlacklisted: rm -rf is blocked",
        isCommandBlacklisted("rm -rf /"))
    testCondition("isCommandBlacklisted: ls is safe",
        not isCommandBlacklisted("ls -la"))
    testCondition("isCommandBlacklisted: dir is safe",
        not isCommandBlacklisted("dir"))

    # --- Summary ---
    see nl
    see "========================================" + nl
    see "  Results: " + nPass + " passed, " + nFail + " failed, " + nTotal + " total" + nl
    see "========================================" + nl

    if nFail > 0
        see "  *** SOME TESTS FAILED ***" + nl
    else
        see "  All tests passed!" + nl
    ok
}

# ===================================================================
# Test Helpers
# ===================================================================
func testCase cName, actual, expected {
    nTotal++
    if actual = expected
        nPass++
        see "  PASS: " + cName + nl
    else
        nFail++
        see "  FAIL: " + cName + nl
        see "        Expected: [" + expected + "]" + nl
        see "        Actual:   [" + actual + "]" + nl
    ok
}

func testCondition cName, bCondition {
    nTotal++
    if bCondition
        nPass++
        see "  PASS: " + cName + nl
    else
        nFail++
        see "  FAIL: " + cName + nl
    ok
}
