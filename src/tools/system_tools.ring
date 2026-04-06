# ===================================================================
# System & Web Tools — Shell Execution & HTTP for FLASH AI Agent
# ===================================================================
# Provides: executeCommand, searchInFiles, read_url
# Extracted from AgentTools as standalone global functions.
# ===================================================================


func executeCommand cCommand
    if isCommandBlacklisted(cCommand)
        return createErrorResult("SECURITY ERROR: This command is blacklisted for security.")
    ok
    try
        aResult = safeSystem(cCommand, 30)
        if aResult[1]
            return createSuccessResult("Command executed:" + nl + aResult[2])
        else
            return createErrorResult("Command execution failed: " + aResult[2])
        ok
    catch
        return createErrorResult("Command execution failed: " + cCatchError)
    done


func searchInFiles cSearchTerm, cDirectory
    try
        if cDirectory = ""
            cDirectory = "."
        ok

        cSafeTerm = sanitizeShellArg(cSearchTerm)
        if cSafeTerm = ""
            return createErrorResult("Search term is empty or invalid after sanitization.")
        ok

        cCommand = ""
        if iswindows()
            cCommand = 'findstr /s /i "' + cSafeTerm + '" ' + cDirectory + '\*.*'
        else
            cCommand = 'grep -r "' + cSafeTerm + '" ' + cDirectory
        ok

        aResult = safeSystem(cCommand, 30)

        if aResult[1] and len(aResult[2]) > 0
            return createSuccessResult("Search results for '" + cSearchTerm + "':" + nl + aResult[2])
        else
            return createSuccessResult("No matches found for '" + cSearchTerm + "'")
        ok
    catch
        return createErrorResult("Search failed: " + cCatchError)
    done


func read_url cURL
    if type(cURL) != "STRING" or cURL = ""
        return createErrorResult("Invalid URL")
    ok
    try
        oClient = new HTTPClient()
        oRes = oClient.getrequest(cURL, [])
        oClient.cleanup()
        if oRes != NULL and type(oRes) = "STRING"
            return createSuccessResult("Content from " + cURL + ":" + nl + oRes)
        else
            return createErrorResult("Failed to fetch URL or empty content")
        ok
    catch
        return createErrorResult("HTTP fetch error: " + cCatchError)
    done
