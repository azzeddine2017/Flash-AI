# ===================================================================
# Utils - Shared Utility Functions for FLASH AI
# Eliminates code duplication across modules
# ===================================================================


# ===================================================================
# Global Application Path Resolver
# ===================================================================

$_FLASH_AI_ROOT_ = ""

func APP_PATH cRelativePath
    if $_FLASH_AI_ROOT_ = ""
        if len(sysargv) >= 2
            # sysargv[2] is the script path
            cScript = lower(sysargv[2])
            cScript = substr(cScript, "/", "\")
            # If not absolute, make it absolute using current working dir
            if len(cScript) > 1 and cScript[2] != ":"
                if left(cScript, 2) = ".\" cScript = substr(cScript, 3) ok
                if left(cScript, 1) != "\"
                    cScript = lower(CurrentDir()) + "\" + cScript
                ok
            ok
            
            aParts = split(cScript, "\")
            if len(aParts) > 1
                del(aParts, len(aParts))
                cRoot = ""
                for p in aParts cRoot += p + "\" next
                $_FLASH_AI_ROOT_ = cRoot
            else
                cRoot = lower(CurrentDir())
                if right(cRoot, 1) != "\" cRoot += "\" ok
                $_FLASH_AI_ROOT_ = cRoot
            ok
        else
            cRoot = lower(CurrentDir())
            if right(cRoot, 1) != "\" cRoot += "\" ok
            $_FLASH_AI_ROOT_ = cRoot
        ok
    ok
    
    # Return absolute path
    cRelativePath = substr(cRelativePath, "/", "\")
    if left(cRelativePath, 1) = "\" cRelativePath = substr(cRelativePath, 2) ok
    return $_FLASH_AI_ROOT_ + cRelativePath

# ===================================================================
# JSON Encoding / Escaping
# ===================================================================

# Escape a string for safe JSON embedding
func jsonEscapeStr cStr
    if type(cStr) != "STRING" return "" ok
    cStr = substr(cStr, char(92), char(92)+char(92))
    cStr = substr(cStr, char(34), char(92)+char(34))
    cStr = substr(cStr, char(10), char(92)+"n")
    cStr = substr(cStr, char(13), char(92)+"r")
    cStr = substr(cStr, char(9),  char(92)+"t")
    return cStr

# ===================================================================
# Bulletproof JSON encoder for Ring lists
# Handles objects (list of [key, value] pairs) and arrays
# ===================================================================
func jsonEncodeValue oVal
    if type(oVal) = "NUMBER" return "" + oVal ok
    if type(oVal) = "STRING" 
        return '"' + jsonEscapeStr(oVal) + '"'
    ok
    if type(oVal) = "LIST"
        # Check for special marker to force empty object {}
        if len(oVal) = 1 and type(oVal[1]) = "LIST"
            if len(oVal[1]) = 2 and oVal[1][1] = ":_is_object" and oVal[1][2] = true
                return "{}"
            ok
        ok

        # Check if this is an object (list of [key, value] pairs)
        bIsObject = true
        if len(oVal) = 0  bIsObject = false  ok
        for item in oVal
            if type(item) != "LIST" or len(item) != 2 or type(item[1]) != "STRING"
                bIsObject = false
                exit
            ok
        next
        
        if bIsObject
            cJSON = "{"
            for i = 1 to len(oVal)
                item = oVal[i]
                cKey = item[1]
                val  = item[2]
                cJSON += '"' + cKey + '":' + jsonEncodeValue(val)
                if i < len(oVal)  cJSON += ","  ok
            next
            cJSON += "}"
            return cJSON
        else
            cJSON = "["
            for i = 1 to len(oVal)
                cJSON += jsonEncodeValue(oVal[i])
                if i < len(oVal)  cJSON += ","  ok
            next
            cJSON += "]"
            return cJSON
        ok
    ok
    if oVal = NULL return "null" ok
    return "null"

# ===================================================================
# Key-Value Lookup (for Ring associative lists)
# ===================================================================

# Get value from a Ring associative list by key
# Supports both [[key, val], ...] and flat [key1, val1, key2, val2] formats
func getValueFromList aList, cKey, cDefault
    if type(aList) != "LIST" return cDefault ok
    # Check against list of pairs (Ring associative list)
    for oItem in aList
        if type(oItem) = "LIST" and len(oItem) >= 2
            if type(oItem[1]) = "STRING"
                if oItem[1] = cKey or (left(oItem[1], 1) = ":" and substr(oItem[1], 2) = cKey)
                    return oItem[2]
                ok
            elseif oItem[1] = cKey
                return oItem[2]
            ok
        ok
    next
    # Fallback for flat lists [key1, val1, key2, val2]
    for i = 1 to len(aList) step 2
        if i < len(aList) and aList[i] = cKey
            return aList[i+1]
        ok
    next
    return cDefault

# ===================================================================
# Session ID Generation (longer, more unique)
# ===================================================================

func generateUniqueId
    random(clock())
    cChars = "abcdef0123456789"
    cId = ""
    for i = 1 to 12
        cId += cChars[(random(100) % 16) + 1]
    next
    return cId

# ===================================================================
# Input Sanitization
# ===================================================================

# Sanitize user input to prevent command injection
func sanitizeInput cInput
    if type(cInput) != "STRING" return "" ok
    # Remove dangerous shell characters
    aDangerous = ["|", ";", "&", "`", "$", "(", ")", "{", "}"]
    for cChar in aDangerous
        cInput = substr(cInput, cChar, "")
    next
    return trim(cInput)

# ===================================================================
# Path Validation
# ===================================================================

# Check if a path is safe (no traversal attacks)
func isPathSafeCheck cPath
    cRoot = getFullPath(CurrentDir())
    if right(cRoot, 1) != "\" cRoot += "\" ok

    # If it's a relative path, make it absolute for checking
    if cPath = "." or cPath = "./" or cPath = ".\"
        cPath = cRoot
    elseif len(cPath) > 0 and len(cPath) < 2 or (len(cPath) >= 2 and cPath[2] != ":")
        if left(cPath, 2) = "./" or left(cPath, 2) = ".\"
            cPath = substr(cPath, 3)
        ok
        if left(cPath, 1) != "/" and left(cPath, 1) != "\"
            cPath = cRoot + cPath
        ok
    ok

    # Normalize path
    cPath = getFullPath(cPath)

    # Prevent accessing outside the current working dir using .. or absolute paths not under root
    if substr(cPath, "..") return false ok
    
    # Sensitive Paths
    if substr(cPath, "config\") or substr(cPath, "api_keys.json") or substr(cPath, ".env")
        return false 
    ok
    
    # Protect core files from unauthorized access/scanning
    /*aBlacklist = ["main.ring", "core_agent.ring", "smart_agent.ring", "agent_tools.ring", "ai_client.ring", "context_engine.ring"]
    for cCore in aBlacklist
        if substr(cPath, cCore) return false ok
    next   */ 

    # If the path starts with the root, it's safe
    if left(cPath, len(cRoot)) != cRoot
        return false
    ok
    return true

# ===================================================================
# Get full absolute path and normalize format
# ===================================================================
func getFullPath cPath
    cPath = lower(cPath)
    cPath = substr(cPath, "/", "\") # Normalize to backslashes
    return cPath

# ===================================================================
# Security Helpers
# ===================================================================

# List of tools that modify the filesystem or run commands
func isSensitiveToolCheck cName
    aSensitive = ["write_file", "delete_file", "run_ring_code", 
                  "execute_command", "git_commit", "create_project", 
                  "replace_file_content", "evolve_new_tool", "delegate_task"]
    return find(aSensitive, cName) > 0

# List of tools that take file paths as parameters
func isPathToolCheck cName
    aPathTools = ["read_file", "write_file", "delete_file", "list_files",
                  "create_directory", "analyze_project", "replace_file_content",
                  "grep_search", "search_in_files"]
    return find(aPathTools, cName) > 0

# ===================================================================
# String Helpers
# ===================================================================

# Count occurrences of a substring in a string
func countSubstring cString, cSubString
    if type(cString) != "STRING" or type(cSubString) != "STRING" return 0 ok
    nCount = 0
    while true
        nPos = substr(cString, cSubString)
        if nPos = 0
            exit
        ok
        nCount++
        cString = substr(cString, nPos + len(cSubString))
    end
    return nCount

# ===================================================================
# Check if text contains Arabic characters
# ===================================================================
func hasArabicText cText
    for i = 1 to len(cText)
        if ascii(cText[i]) >= 192 return true ok
    next
    return false

# ===================================================================
# Simple Markdown to HTML converter for Gui
# ===================================================================
func renderMarkdown cText
    if cText = "" or cText = null return "" ok
    cHtml = cText
    # Handle Newlines
    cHtml = substr(cHtml, nl, "<br>")
    # Handle bold **text**
    # Using simple search/replace for common patterns
    cHtml = substr(cHtml, "```", "<pre style='background:#1c2128; padding:10px; border-radius:5px; color:#d19a66; border-left:3px solid #d19a66;'>")
    # Handle simple lists
    cHtml = substr(cHtml, nl + "- ", nl + "<li>")
    cHtml = substr(cHtml, nl + "* ", nl + "<li>")
    # Wrap in code blocks if needed
    if countSubstring(cHtml, "<pre") > 0
        # Simple heuristic to close blocks
        if countSubstring(cHtml, "<pre") > countSubstring(cHtml, "</pre")
            cHtml += "</pre>"
        ok
    ok
    return cHtml

# ===================================================================
# Ensure a directory exists, create if not
# ===================================================================
func ensureDirectoryExists cDir
    if not dirExists(cDir)
        makedir(cDir)
    ok

# ===================================================================
# Command Safety
# ===================================================================

# Check if a shell command is in the blacklist
func isCommandBlacklisted cCommand
    cLower = lower(trim(cCommand))
    aBlacklist = ["format", "del /", "del \", "rmdir /s", 
                  "rm -rf", "rm -r", "shutdown", "reboot",
                  "mkfs", "dd if=", ":(){", "wget", "curl -o"]
    for cBad in aBlacklist
        if substr(cLower, cBad) return true ok
    next
    return false

# ===================================================================
# Shell Argument Sanitization (Prevents Injection)
# ===================================================================

# Sanitize a string before embedding it inside a shell command argument.
# Strips characters that could escape the quoting context or inject commands.
func sanitizeShellArg cArg
    if type(cArg) != "STRING" return "" ok
    # Remove characters that can break out of a quoted shell argument
    # Also strip: % (Windows env expansion), .. (path traversal)
    aDangerous = ['"', "'", "`", "|", ";", "&", "$", 
                  "(", ")", "{", "}", "<", ">", "!", "%",
                  char(10), char(13)]
    for cChar in aDangerous
        cArg = substr(cArg, cChar, "")
    next
    # Strip path traversal sequences
    cArg = substr(cArg, "..", "")
    return trim(cArg)

# ===================================================================
# Safe System Command Execution (With Timeout Protection)
# ===================================================================

# Execute a shell command with output captured to a temp file.
# Prevents infinite blocking by using OS-level timeout (Unix) or
# bounded output capture (Windows). Returns [success, output] list.
func safeSystem cCommand, nTimeoutSec
    if type(nTimeoutSec) != "NUMBER" or nTimeoutSec <= 0
        nTimeoutSec = 30
    ok
    
    cTempOut = APP_PATH("ai/logs/cmd_" + clock() + "_" + random(9999) + ".tmp")
    
    try
        if iswindows()
            # Windows: use direct system() for very short commands to reduce file Latency
            # For longer ones, use cmd /c with redirect and powershell timeout wrapper
            if len(cCommand) < 30 and not substr(cCommand, ">") 
                # Direct execute for small safe commands
                system(cCommand + ' > "' + cTempOut + '" 2>&1')
            else
                # Bounded execution using powershell
                cPSCmd = 'powershell -NoProfile -Command "$p = Start-Process cmd -ArgumentList ' + "'/c " + '"""' + cCommand + ' > ' + cTempOut + ' 2>&1' + '"""' + "'" + ' -PassThru -NoNewWindow; if (!$p.WaitForExit(' + (nTimeoutSec * 1000) + ')) { $p.Kill(); [System.IO.File]::AppendAllText(' + "'" + cTempOut + "'" + ', \'TIMEOUT: Command exceeded ' + nTimeoutSec + 's limit\') }"'
                system(cPSCmd)
            ok
        else
            # Unix: use timeout command for hard time limit
            cWrapped = "timeout " + nTimeoutSec + " sh -c '" + cCommand + "' > " + cTempOut + " 2>&1"
            system(cWrapped)
        ok
        
        cOutput = ""
        # Small delay for OS to flush file buffer if needed
        # sleep(0.1) 
        if fexists(cTempOut)
            cOutput = read(cTempOut)
            try remove(cTempOut) catch done
        ok
        
        # Check for timeout marker
        if substr(cOutput, "TIMEOUT: Command exceeded")
            return [false, "Command timed out after " + nTimeoutSec + " seconds."]
        ok
        
        return [true, cOutput]
    catch
        # Clean up temp file on error
        if fexists(cTempOut)
            try remove(cTempOut) catch done
        ok
        return [false, "Command failed: " + cCatchError]
    done

# ===================================================================
# Evolved Tool Code Validation (Sandbox Check)
# ===================================================================

# Check if Ring source code contains dangerous patterns that should not
# be allowed in AI-generated custom tools (prevents privilege escalation).
func validateToolCode cCode
    if type(cCode) != "STRING" or trim(cCode) = ""
        return [false, "Empty code is not allowed"]
    ok
    
    cLower = lower(cCode)
    
    # Dangerous pattern checks
    aDangerous = [
        ["system(", "Direct system() calls are not allowed in custom tools. Use execute_command tool instead."],
        ["systemcmd(", "Direct systemcmd() calls are not allowed in custom tools. Use execute_command tool instead."],
        ["eval(", "Nested eval() calls are not allowed in custom tools for security."],
        ["api_key", "Accessing API keys is not allowed in custom tools."],
        [".env", "Accessing .env files is not allowed in custom tools."],
        ["curl_easy", "Direct libcurl access is not allowed in custom tools."],
        ["fopen(", "Direct fopen() is not allowed. Use read/write file tools instead."],
        ["remove(", "Direct remove() is not allowed. Use delete_file tool instead."]
    ]
    
    for aCheck in aDangerous
        if substr(cLower, aCheck[1])
            return [false, "SECURITY: " + aCheck[2]]
        ok
    next
    
    # Must define at least one function
    if not substr(cLower, "func ")
        return [false, "Custom tool code must define at least one function (func toolname ...)."]
    ok
    
    return [true, "Code passed validation"]

# ===================================================================
# Token Estimator (Optimized for Arabic & Code)
# ===================================================================
func estimateTokens(cText)
    if type(cText) != "STRING" return 0 ok
    
    nLen = len(cText)
    if nLen = 0 return 0 ok
    
    # For English/Code, one token is approximately 4 characters
    # For Arabic, one token may be only 2 characters due to Unicode
    if isfunction("hasArabicText") and hasArabicText(cText)
        return ceil(nLen / 2.5)
    ok
    
    return ceil(nLen / 4.0)

# ===================================================================
# Exponential Backoff for Rate Limit Retries
# Replaces fixed sleep(12) with adaptive delay: 4, 8, 16, 32, 60 max
# ===================================================================

func retryWithBackoff nAttempt
    nDelay = 2 * pow(2, nAttempt)  # 4, 8, 16, 32...
    if nDelay > 60  nDelay = 60  ok
    see "  [!] Rate limit: waiting " + nDelay + "s before retry " + nAttempt + "..." + nl
    sleep(nDelay)
    return nDelay

func pow nBase, nExp
    if nExp <= 0 return 1 ok
    nResult = 1
    for i = 1 to nExp
        nResult *= nBase
    next
    return nResult

# ===================================================================
# Global Tool Result Helpers
# Used by standalone tool functions in src/tools/
# ===================================================================

func createSuccessResult cMessage
    return createSuccessResultExtended(cMessage, 0, 0)

func createSuccessResultExtended cMessage, nAdded, nRemoved
    return [
        :success = true,
        :message = cMessage,
        :added = nAdded,
        :removed = nRemoved,
        :error = ""
    ]
# ===================================================================
# Error Result
# ===================================================================
func createErrorResult cError
    return [
        :success = false,
        :message = "",
        :added = 0,
        :removed = 0,
        :error = cError
    ]

# ===================================================================
# Robust JSON Encoding
# ===================================================================

func jsonEncodeRecursive(oVal)
    if type(oVal) = "NUMBER" return "" + oVal ok
    if type(oVal) = "STRING" return '"' + jsonEscapeStr(oVal) + '"' ok
    if type(oVal) = "LIST"
        # Check for empty object marker
        if len(oVal) = 1 and type(oVal[1]) = "LIST"
            if len(oVal[1]) = 2 and oVal[1][1] = ":_is_object" and oVal[1][2] = true
                return "{}"
            ok
        ok
        
        # Check if it's an object-style list (pairs of [key, value])
        if len(oVal) > 0 and type(oVal[1]) = "LIST" and len(oVal[1]) = 2 and type(oVal[1][1]) = "STRING"
            cJSON = "{"
            for i = 1 to len(oVal)
                if i > 1 cJSON += "," ok
                cKey = oVal[i][1]
                cVal = oVal[i][2]
                cJSON += '"' + cKey + '":' + jsonEncodeRecursive(cVal)
            next
            return cJSON + "}"
        else
            cJSON = "["
            for i = 1 to len(oVal)
                if i > 1 cJSON += "," ok
                cJSON += jsonEncodeRecursive(oVal[i])
            next
            return cJSON + "]"
        ok
    ok
    if oVal = NULL return "null" ok
    return "null"
