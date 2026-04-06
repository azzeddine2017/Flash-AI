# ===================================================================
# Project & Git Tools — Project Management for FLASH AI Agent
# ===================================================================
# Provides: createProject, analyzeProject,
#           gitInit, gitStatus, gitAdd, gitCommit
# Extracted from AgentTools as standalone global functions.
# ===================================================================


func createProject cProjectName, cProjectType
    try
        if dirExists(cProjectName)
            return createErrorResult("Project directory already exists: " + cProjectName)
        ok
        makedir(cProjectName)
        makedir(cProjectName + "/src")
        makedir(cProjectName + "/docs")
        makedir(cProjectName + "/tests")

        cMainContent = "# " + cProjectName + " - Ring Project" + nl +
                      "# Created: " + date() + " " + time() + nl + nl +
                      'load "stdlib.ring"' + nl + nl +
                      "func main()" + nl +
                      '    see "Welcome to ' + cProjectName + '!" + nl' + nl +
                      "ok" + nl
        write(cProjectName + "/main.ring", cMainContent)

        cReadmeContent = "# " + cProjectName + nl + nl +
                       "Ring programming project created on " + date() + nl + nl +
                       "## Structure" + nl +
                       "- `src/` - Source code files" + nl +
                       "- `docs/` - Documentation" + nl +
                       "- `tests/` - Test files" + nl +
                       "- `main.ring` - Main application file" + nl
        write(cProjectName + "/README.md", cReadmeContent)

        return createSuccessResult("Project created successfully: " + cProjectName)
    catch
        return createErrorResult("Failed to create project: " + cCatchError)
    done


func analyzeProject cProjectPath
    try
        if not dirExists(cProjectPath)
            return createErrorResult("Project path not found: " + cProjectPath)
        ok

        cAnalysis = "Project Analysis: " + cProjectPath + nl + nl
        nRingFiles = 0
        nTotalFiles = 0

        cCommand = ""
        if iswindows()
            cCommand = "dir " + cProjectPath + " /s /b"
        else
            cCommand = "find " + cProjectPath + " -type f"
        ok

        aSysResult = safeSystem(cCommand, 30)
        cFileList = ""
        if aSysResult[1] cFileList = aSysResult[2] ok
        aFiles = str2list(cFileList)

        for cFile in aFiles
            cFile = trim(cFile)
            if len(cFile) > 0
                nTotalFiles++
                if substr(cFile, ".ring")  nRingFiles++  ok
            ok
        next

        cAnalysis += "Total files: " + nTotalFiles + nl
        cAnalysis += "Ring files: " + nRingFiles + nl + nl
        cAnalysis += "Project Structure:" + nl

        if fexists(cProjectPath + "/main.ring")
            cAnalysis += "✓ main.ring found" + nl
        else
            cAnalysis += "✗ main.ring missing" + nl
        ok
        if dirExists(cProjectPath + "/src")
            cAnalysis += "✓ src/ directory found" + nl
        else
            cAnalysis += "✗ src/ directory missing" + nl
        ok
        if fexists(cProjectPath + "/README.md")
            cAnalysis += "✓ README.md found" + nl
        else
            cAnalysis += "✗ README.md missing" + nl
        ok

        return createSuccessResult(cAnalysis)
    catch
        return createErrorResult("Project analysis failed: " + cCatchError)
    done


func gitInit
    try
        cResult = systemcmd("git init")
        return createSuccessResult("Git repository initialized:" + nl + cResult)
    catch
        return createErrorResult("Git init failed: " + cCatchError)
    done

func gitStatus
    try
        aResult = safeSystem("git status", 15)
        if aResult[1]
            return createSuccessResult("Git status:" + nl + aResult[2])
        else
            return createErrorResult("Git status failed: " + aResult[2])
        ok
    catch
        return createErrorResult("Git status failed: " + cCatchError)
    done

func gitAdd cFiles
    try
        aResult = safeSystem("git add " + cFiles, 15)
        if aResult[1]
            return createSuccessResult("Files added to Git:" + nl + aResult[2])
        else
            return createErrorResult("Git add failed: " + aResult[2])
        ok
    catch
        return createErrorResult("Git add failed: " + cCatchError)
    done

func gitCommit cMessage
    try
        cSafeMsg = sanitizeShellArg(cMessage)
        aResult = safeSystem('git commit -m "' + cSafeMsg + '"', 15)
        if aResult[1]
            return createSuccessResult("Git commit completed:" + nl + aResult[2])
        else
            return createErrorResult("Git commit failed: " + aResult[2])
        ok
    catch
        return createErrorResult("Git commit failed: " + cCatchError)
    done
