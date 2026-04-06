# ===================================================================
# SecurityLayer - Centralized Security Validation & Audit System
# ===================================================================
# Provides:
#   - Risk-level classification for every tool execution
#   - Centralized audit trail of all tool actions
#   - Path whitelisting with scope enforcement
#   - Authorization gating for high-risk operations
# ===================================================================

class SecurityLayer

    # Authorization State
    bAuthorized = false

    # Audit Configuration
    aAuditLog = []
    nMaxAuditEntries = 500
    cAuditFile = ""

    # Path Whitelist (directories the agent is allowed to access)
    aPathWhitelist = []

    # Risk Classification (tool -> risk level)
    aToolRiskMap = []

    # ===================================================================
    # Constructor
    # ===================================================================
    func init
        cAuditFile = APP_PATH("ai/logs/security_audit.log")
        ensureDirectoryExists(APP_PATH("ai/logs"))

        # Set working directory as default whitelist root
        aPathWhitelist + lower(CurrentDir())

        # Define risk levels for known tools
        aToolRiskMap = [
            ["read_file",              "low"],
            ["list_files",             "low"],
            ["grep_search",            "low"],
            ["search_in_files",        "low"],
            ["analyze_code",           "low"],
            ["read_url",               "low"],
            ["context_summarizer",     "low"],
            ["write_file",             "medium"],
            ["replace_file_content",   "medium"],
            ["create_directory",       "medium"],
            ["git_init",               "medium"],
            ["git_add",                "medium"],
            ["git_status",             "low"],
            ["create_project",         "medium"],
            ["run_ring_code",          "high"],
            ["delete_file",            "high"],
            ["git_commit",             "high"],
            ["execute_command",        "critical"],
            ["evolve_new_tool",        "critical"],
            ["delegate_task",          "high"]
        ]

    # ===================================================================
    # Authorize / Revoke
    # ===================================================================
    func authorize
        bAuthorized = true
        logAudit("SYSTEM", "Authorization granted", "info")

    func revoke
        bAuthorized = false
        logAudit("SYSTEM", "Authorization revoked", "info")

    func isAuthorized
        return bAuthorized

    # ===================================================================
    # Tool Risk Classification
    # ===================================================================
    func getToolRisk cToolName
        cToolLower = lower(trim(cToolName))
        for aEntry in aToolRiskMap
            if aEntry[1] = cToolLower
                return aEntry[2]
            ok
        next
        # Unknown tools default to high risk
        return "high"

    # ===================================================================
    # Validate Tool Execution
    # ===================================================================
    # Returns: [allowed (bool), reason (string), risk_level (string)]
    func validateToolExecution cToolName, aParams
        cRisk = getToolRisk(cToolName)
        cParamSummary = summarizeParams(aParams)

        # Critical tools require authorization
        if cRisk = "critical" and not bAuthorized
            logAudit(cToolName, "BLOCKED (unauthorized critical tool) | " + cParamSummary, "warn")
            return [false, "Critical tool '" + cToolName + "' requires /authorize", cRisk]
        ok

        # High-risk tools log a warning but are allowed (UI confirmation handles these)
        if cRisk = "high" and not bAuthorized
            logAudit(cToolName, "FLAGGED (high-risk, needs confirmation) | " + cParamSummary, "warn")
        ok

        # All tools: log the execution
        logAudit(cToolName, "ALLOWED [" + cRisk + "] | " + cParamSummary, "info")

        return [true, "", cRisk]

    # ===================================================================
    # Path Validation Against Whitelist
    # ===================================================================
    func isPathAllowed cPath
        if bAuthorized return true ok

        cNorm = lower(cPath)
        cNorm = substr(cNorm, "/", "\")

        for cAllowed in aPathWhitelist
            cAllowedNorm = lower(cAllowed)
            cAllowedNorm = substr(cAllowedNorm, "/", "\")
            if right(cAllowedNorm, 1) != "\"
                cAllowedNorm += "\"
            ok
            if left(cNorm, len(cAllowedNorm)) = cAllowedNorm
                return true
            ok
        next

        logAudit("PATH_CHECK", "DENIED: " + cPath, "warn")
        return false

    # ===================================================================
    # Add Path to Whitelist
    # ===================================================================
    func addPathToWhitelist cPath
        cNorm = lower(cPath)
        if find(aPathWhitelist, cNorm) = 0
            aPathWhitelist + cNorm
            logAudit("WHITELIST", "Added: " + cPath, "info")
        ok

    # ===================================================================
    # Audit Logging
    # ===================================================================
    func logAudit cSource, cMessage, cLevel
        cTimestamp = date() + " " + time()
        oEntry = [
            ["timestamp", cTimestamp],
            ["source", cSource],
            ["message", cMessage],
            ["level", cLevel]
        ]
        aAuditLog + oEntry

        # Prune old entries
        if len(aAuditLog) > nMaxAuditEntries
            del(aAuditLog, 1)
        ok

        # Persist to file
        try
            cLine = "[" + cTimestamp + "] [" + upper(cLevel) + "] " + cSource + " | " + cMessage + nl
            fp = fopen(cAuditFile, "a")
            if fp != NULL
                fwrite(fp, cLine)
                fclose(fp)
            ok
        catch
            # Silent fail — never crash due to audit logging
        done

    # ===================================================================
    # Audit Report
    # ===================================================================
    func getAuditReport nLastN
        if nLastN = 0 or nLastN = NULL
            nLastN = 20
        ok
        cReport = "=== Security Audit Log (last " + nLastN + " entries) ===" + nl + nl
        nStart = max(1, len(aAuditLog) - nLastN + 1)
        for i = nStart to len(aAuditLog)
            oEntry = aAuditLog[i]
            cReport += getValueFromList(oEntry, "timestamp", "") + " | "
            cReport += left(getValueFromList(oEntry, "source", "") + copy(" ", 20), 20) + " | "
            cReport += getValueFromList(oEntry, "level", "") + " | "
            cReport += getValueFromList(oEntry, "message", "") + nl
        next
        return cReport

    # ===================================================================
    # Statistics
    # ===================================================================
    func getStats
        nTotal = len(aAuditLog)
        nBlocked = 0
        nWarnings = 0
        for oEntry in aAuditLog
            cMsg = lower(getValueFromList(oEntry, "message", ""))
            if substr(cMsg, "blocked") nBlocked++ ok
            cLvl = getValueFromList(oEntry, "level", "")
            if cLvl = "warn" nWarnings++ ok
        next
        return [
            ["total_actions", nTotal],
            ["blocked", nBlocked],
            ["warnings", nWarnings],
            ["authorized", bAuthorized]
        ]

    # ===================================================================
    # Private Helpers
    # ===================================================================
    private

    func summarizeParams aParams
        if type(aParams) != "LIST" return "(no params)" ok
        if len(aParams) = 0 return "(no params)" ok
        cSummary = ""
        for i = 1 to min(3, len(aParams))
            cVal = ""
            if type(aParams[i]) = "STRING"
                cVal = left(aParams[i], 60)
            elseif type(aParams[i]) = "LIST" and len(aParams[i]) >= 2
                cVal = "" + aParams[i][1] + "=" + left("" + aParams[i][2], 40)
            else
                cVal = "(complex)"
            ok
            if i > 1 cSummary += ", " ok
            cSummary += cVal
        next
        return cSummary

    func max a, b
        if a > b return a ok
        return b

    func min a, b
        if a < b return a ok
        return b
