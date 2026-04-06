# ===================================================================
# File Tools — File System Operations for FLASH AI Agent
# ===================================================================
# Provides: writeFile, readFile, deleteFile, listFiles,
#           createDirectory, replace_file_content, grep_search
# Extracted from AgentTools as standalone global functions.
# ===================================================================


func writeFile cFileName, cContent
    try
        if islist(cFileName) cFileName = list2str(cFileName) ok
        if islist(cContent) cContent = list2str(cContent) ok
        cFileName = "" + cFileName
        cContent = "" + cContent

        # Auto-create directory if path includes folders
        if substr(cFileName, "/") or substr(cFileName, "\")
            cDir = ""
            aParts = []
            if substr(cFileName, "/") aParts = split(cFileName, "/") ok
            if substr(cFileName, "\") aParts = split(cFileName, "\") ok
            if len(aParts) > 1
                for i = 1 to len(aParts) - 1
                    if i > 1  cDir += "/"  ok
                    cDir += aParts[i]
                    if not dirExists(cDir) system("mkdir " + cDir) ok
                next
            ok
        ok

        nRemoved = 0
        if fexists(cFileName)
            nRemoved = len(str2list(read(cFileName)))
        ok
        write(cFileName, cContent)
        nAdded = len(str2list(cContent))
        return createSuccessResultExtended("File written successfully: " + cFileName, nAdded, nRemoved)
    catch
        return createErrorResult("Failed to write file: " + cCatchError)
    done


func readFile cFileName
    try
        cFileName = "" + cFileName
        if fexists(cFileName)
            cContent = read(cFileName)
            return createSuccessResult("File content:" + nl + cContent)
        else
            return createErrorResult("File not found: " + cFileName)
        ok
    catch
        return createErrorResult("Failed to read file: " + cCatchError)
    done


func deleteFile cFileName
    try
        cFileName = "" + cFileName
        if fexists(cFileName)
            remove(cFileName)
            return createSuccessResult("File deleted successfully: " + cFileName)
        else
            return createErrorResult("File not found: " + cFileName)
        ok
    catch
        return createErrorResult("Failed to delete file: " + cCatchError)
    done


func listFiles cDirectory
    try
        cDirectory = "" + cDirectory
        if type(cDirectory) = "NULL" or trim(cDirectory) = "" or cDirectory = NULL or cDirectory = "'.'" or cDirectory = '"."'
            cDirectory = "."
        ok
        cCommand = ""
        if iswindows()
            # Normalize to avoid confusing dir with quotes if unnecessary
            cDirectory = substr(cDirectory, "/", "\")
            cCommand = "dir " + cDirectory + " /b"
        else
            cCommand = "ls " + cDirectory
        ok
        aResult = safeSystem(cCommand, 30) # Increased timeout to 30s
        if aResult[1]
            return createSuccessResult("Files in " + cDirectory + ":\n" + aResult[2])
        else
            return createErrorResult("Failed to list files: " + aResult[2])
        ok
    catch
        return createErrorResult("Failed to list files: " + cCatchError)
    done


func createDirectory cDirName
    try
        if not dirExists(cDirName)
            makedir(cDirName)
            return createSuccessResult("Directory created: " + cDirName)
        else
            return createErrorResult("Directory already exists: " + cDirName)
        ok
    catch
        return createErrorResult("Failed to create directory: " + cCatchError)
    done


func replace_file_content cFileName, cTarget, cReplacement
    try
        if islist(cFileName) cFileName = list2str(cFileName) ok
        if islist(cTarget) cTarget = list2str(cTarget) ok
        if islist(cReplacement) cReplacement = list2str(cReplacement) ok
        cFileName = "" + cFileName
        cTarget = "" + cTarget
        cReplacement = "" + cReplacement

        if fexists(cFileName)
            cContent = read(cFileName)
            nRem = len(str2list(cTarget))
            nAdd = len(str2list(cReplacement))

            # Try exact match first
            if substr(cContent, cTarget)
                cNewContent = substr(cContent, cTarget, cReplacement)
                write(cFileName, cNewContent)
                return createSuccessResultExtended("File edited successfully: " + cFileName, nAdd, nRem)
            ok

            # Try match with trimmed strings (fallback)
            aLines = str2list(cContent)
            bFound = false
            cTargetTrim = trim(cTarget)
            for i = 1 to len(aLines)
                if trim(aLines[i]) = cTargetTrim
                    if not substr(cReplacement, nl)
                        cLead = ""
                        for j = 1 to len(aLines[i])
                            if aLines[i][j] = " " or aLines[i][j] = char(9)
                                cLead += aLines[i][j]
                            else
                                exit
                            ok
                        next
                        aLines[i] = cLead + cReplacement
                    else
                        aLines[i] = cReplacement
                    ok
                    bFound = true
                    exit
                ok
            next

            if bFound
                cNewContent = list2str(aLines)
                write(cFileName, cNewContent)
                return createSuccessResultExtended("File edited successfully (Smart Match): " + cFileName, nAdd, 1)
            else
                return createErrorResult("Target text not found: " + cTarget)
            ok
        else
            return createErrorResult("File not found: " + cFileName)
        ok
    catch
        return createErrorResult("Failed to edit file: " + cCatchError)
    done


func grep_search cPattern, cDir
    try
        cSafePattern = sanitizeShellArg(cPattern)
        if cSafePattern = ""
            return createErrorResult("Search pattern is empty or invalid after sanitization.")
        ok
        if isWindows()
            cCmd = 'findstr /S /I /C:"' + cSafePattern + '" ' + cDir + '\*.ring'
        else
            cCmd = 'grep -r -i "' + cSafePattern + '" ' + cDir
        ok
        return executeCommand(cCmd)
    catch
        return createErrorResult("Failed to search project: " + cCatchError)
    done
