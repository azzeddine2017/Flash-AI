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
        cAuditFile = APP_PATH("logs/security_audit.log")
        ensureDirectoryExists(APP_PATH("logs"))

        # Set working directory as default whitelist root
        aPathWhitelist + canonicalPath(CurrentDir())

        # Define risk levels for known tools (Project-scoped tools are low risk)
        aToolRiskMap = [
            ["read_file",              "low"],
            ["list_files",             "low"],
            ["grep_search",            "low"],
            ["search_in_files",        "low"],
            ["analyze_code",           "low"],
            ["read_url",               "low"],
            ["context_summarizer",     "low"],
            ["list_skills",            "low"],
            ["activate_skill",         "low"],
            ["read_skill",             "low"],
            ["save_skill",             "medium"],
            ["modify_skill",           "medium"],
            ["delete_skill",           "high"],
            ["remember_fact",          "low"],
            ["recall_memory",          "low"],
            ["view_memory",            "low"],
            ["forget_fact",            "medium"],
            ["write_file",             "medium"],
            ["replace_file_content",   "medium"],
            ["create_directory",       "medium"],
            ["git_init",               "low"],
            ["git_add",                "low"],
            ["git_status",             "low"],
            ["create_project",         "medium"],
            ["git_commit",             "medium"],
            ["delegate_task",          "medium"],
            ["evolve_new_tool",        "high"],
            ["delete_file",            "high"],
            ["run_ring_code",          "high"],
            ["execute_command",        "critical"]
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
        # Unknown/dynamic custom tools default to medium risk
        return "medium"

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

        # High-risk tools also require authorization (defense in depth)
        if cRisk = "high" and not bAuthorized
            logAudit(cToolName, "BLOCKED (unauthorized high-risk tool) | " + cParamSummary, "warn")
            return [false, "High-risk tool '" + cToolName + "' requires user confirmation or /authorize", cRisk]
        ok

        # All tools: log the execution
        logAudit(cToolName, "ALLOWED [" + cRisk + "] | " + cParamSummary, "info")

        return [true, "", cRisk]

    # ===================================================================
    # Path Canonicalization Helper (Resolves relative paths and '..')
    # ===================================================================
    func canonicalPath cPath
        cPath = trim("" + cPath)
        if cPath = "" return "" ok
        cNorm = substr(cPath, "/", "\")
        
        # Check if already absolute
        bIsAbsolute = false
        if iswindows()
            if len(cNorm) >= 2 and cNorm[2] = ":"
                bIsAbsolute = true
            elseif left(cNorm, 2) = "\\"
                bIsAbsolute = true
            ok
        else
            if left(cNorm, 1) = "/"
                bIsAbsolute = true
            ok
        ok
        
        if not bIsAbsolute
            cCur = substr(CurrentDir(), "/", "\")
            if right(cCur, 1) != "\" cCur += "\" ok
            cNorm = cCur + cNorm
        ok
        
        # Resolve "." and ".."
        aParts = split(cNorm, "\")
        aResolved = []
        for cPart in aParts
            if cPart = "" or cPart = "."
                loop
            elseif cPart = ".."
                if len(aResolved) > 1
                    del(aResolved, len(aResolved))
                ok
            else
                aResolved + cPart
            ok
        next
        
        cResult = ""
        for i = 1 to len(aResolved)
            if i = 1 and iswindows() and right(aResolved[1], 1) = ":"
                cResult = aResolved[1] + "\"
            else
                if cResult != "" and right(cResult, 1) != "\"
                    cResult += "\"
                ok
                cResult += aResolved[i]
            ok
        next
        return lower(cResult)

    # ===================================================================
    # Path Validation Against Whitelist
    # ===================================================================
    func isPathAllowed cPath
        if bAuthorized return true ok

        cNorm = canonicalPath(cPath)
        if cNorm = "" return false ok

        for cAllowed in aPathWhitelist
            cAllowedNorm = canonicalPath(cAllowed)
            if right(cAllowedNorm, 1) != "\"
                cAllowedNorm += "\"
            ok
            # Exact match or directory subpath match
            if cNorm = left(cAllowedNorm, len(cAllowedNorm) - 1) or
               left(cNorm, len(cAllowedNorm)) = cAllowedNorm
                return true
            ok
        next

        logAudit("PATH_CHECK", "DENIED: " + cPath + " (resolved: " + cNorm + ")", "warn")
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
