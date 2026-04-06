# ===================================================================
# Reflection Engine — Self-Correction Loop for Tool Failures
# ===================================================================
# Analyzes tool execution failures and provides:
#   - Error pattern matching with known diagnoses
#   - Recovery prompt generation for the LLM
#   - Retry recommendation based on error type
#   - Failure tracking to prevent infinite retry loops
# ===================================================================


class ReflectionEngine

    # Configuration
    nMaxRetries = 2

    # Known error patterns → diagnosis + suggested action
    aErrorPatterns = []

    # Failure tracking (prevents retrying the same error endlessly)
    aRecentFailures = []
    nMaxTrackedFailures = 20

    # ===================================================================
    # Constructor
    # ===================================================================
    func init
        aErrorPatterns = [
            [["pattern", "file not found"],
             ["diagnosis", "The specified file path does not exist."],
             ["action", "Use list_files to verify the exact path and filename before retrying."]],

            [["pattern", "target text not found"],
             ["diagnosis", "The target string for replacement does not match the actual file content."],
             ["action", "Use read_file to view the current content, then retry with the exact text."]],

            [["pattern", "syntax error"],
             ["diagnosis", "The Ring code has a syntax issue."],
             ["action", "Check: ok/next/done keywords, string escaping, and missing method definitions."]],

            [["pattern", "permission denied"],
             ["diagnosis", "The operation requires elevated permissions."],
             ["action", "Ask the user to type /authorize, or choose an alternative path."]],

            [["pattern", "security error"],
             ["diagnosis", "The security layer blocked this operation on a protected file."],
             ["action", "This file is in the core protection list. Ask for /authorize or use a different approach."]],

            [["pattern", "command not found"],
             ["diagnosis", "The shell command does not exist on this operating system."],
             ["action", "Verify the command name for the current OS (Windows vs Linux)."]],

            [["pattern", "timeout"],
             ["diagnosis", "The operation exceeded the time limit."],
             ["action", "Break the operation into smaller chunks or increase specificity."]],

            [["pattern", "directory already exists"],
             ["diagnosis", "The target directory was already created."],
             ["action", "This is not a real error — proceed with the next step."]],

            [["pattern", "empty response"],
             ["diagnosis", "The API returned no content."],
             ["action", "The model may have hit a safety filter. Rephrase the request."]],

            [["pattern", "resource_exhausted"],
             ["diagnosis", "API rate limit was hit."],
             ["action", "Wait before retrying. The system will auto-retry after a cooldown."]],

            [["pattern", "invalid"],
             ["diagnosis", "Invalid input parameters were provided."],
             ["action", "Review parameter names and types. Check tool definition for expected format."]]
        ]

    # ===================================================================
    # Analyze a tool failure and produce a diagnosis
    # ===================================================================
    func analyzeFailure cToolName, cError, aParams
        cErrorLower = lower("" + cError)

        oAnalysis = [
            ["original_tool", cToolName],
            ["error", cError],
            ["diagnosis", "Unknown error — no matching pattern found."],
            ["suggested_action", "Report the exact error to the LLM for analysis."],
            ["should_retry", false],
            ["is_repeat", false]
        ]

        # Match against known error patterns
        for aPattern in aErrorPatterns
            cPat = getValueFromList(aPattern, "pattern", "")
            if substr(cErrorLower, cPat)
                oAnalysis = [
                    ["original_tool", cToolName],
                    ["error", cError],
                    ["diagnosis", getValueFromList(aPattern, "diagnosis", "")],
                    ["suggested_action", getValueFromList(aPattern, "action", "")],
                    ["should_retry", true],
                    ["is_repeat", false]
                ]
                exit
            ok
        next

        # Check if this is a repeat failure (same tool + similar error)
        for oFail in aRecentFailures
            cPrevTool = getValueFromList(oFail, "tool", "")
            cPrevErr = lower(getValueFromList(oFail, "error", ""))
            if cPrevTool = cToolName and substr(cPrevErr, left(cErrorLower, 30))
                # Same tool, similar error — this is a repeat
                oAnalysis = setListValue(oAnalysis, "is_repeat", true)
                oAnalysis = setListValue(oAnalysis, "should_retry", false)
                oAnalysis = setListValue(oAnalysis, "diagnosis", 
                    getValueFromList(oAnalysis, "diagnosis", "") + " [REPEAT FAILURE — do NOT retry the same approach]")
                exit
            ok
        next

        # Track this failure
        trackFailure(cToolName, cError)

        return oAnalysis

    # ===================================================================
    # Build a recovery prompt to inject into the LLM conversation
    # ===================================================================
    func buildRecoveryPrompt oAnalysis
        cPrompt = "[SELF-CORRECTION PROTOCOL]" + nl
        cPrompt += "Tool: " + getValueFromList(oAnalysis, "original_tool", "") + nl
        cPrompt += "Error: " + getValueFromList(oAnalysis, "error", "") + nl
        cPrompt += "Diagnosis: " + getValueFromList(oAnalysis, "diagnosis", "") + nl
        cPrompt += "Suggested Action: " + getValueFromList(oAnalysis, "suggested_action", "") + nl

        if getValueFromList(oAnalysis, "is_repeat", false)
            cPrompt += "WARNING: This is a REPEAT failure. You must try a fundamentally different approach." + nl
        ok

        cPrompt += "Action: Analyze the error carefully and retry with a corrected approach." + nl
        return cPrompt

    # ===================================================================
    # Check if a retry is recommended
    # ===================================================================
    func shouldRetry oAnalysis
        return getValueFromList(oAnalysis, "should_retry", false)

    # ===================================================================
    # Reset failure tracking (called on new session)
    # ===================================================================
    func reset
        aRecentFailures = []

    # ===================================================================
    # Private: Track failures
    # ===================================================================
    private

    func trackFailure cToolName, cError
        aRecentFailures + [
            ["tool", cToolName],
            ["error", "" + cError],
            ["timestamp", date() + " " + time()]
        ]
        # Keep list bounded
        if len(aRecentFailures) > nMaxTrackedFailures
            del(aRecentFailures, 1)
        ok

    func setListValue aList, cKey, xValue
        for i = 1 to len(aList)
            if type(aList[i]) = "LIST" and len(aList[i]) >= 2
                if aList[i][1] = cKey
                    aList[i][2] = xValue
                    return aList
                ok
            ok
        next
        aList + [cKey, xValue]
        return aList
