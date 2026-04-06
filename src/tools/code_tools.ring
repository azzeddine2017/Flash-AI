# ===================================================================
# Code Tools — Code Execution & Analysis for FLASH AI Agent
# ===================================================================
# Provides: runRingCode, analyzeCode, formatCode
# Extracted from AgentTools as standalone global functions.
# ===================================================================


func runRingCode cCode
    try
        cTempFile = "temp_code_" + clock() + ".ring"
        write(cTempFile, cCode)
        cCommand = "ring " + cTempFile
        aResult = safeSystem(cCommand, 30)
        if fexists(cTempFile)
            remove(cTempFile)
        ok
        if aResult[1]
            return createSuccessResult("Code execution result:" + nl + aResult[2])
        else
            return createErrorResult("Code execution failed: " + aResult[2])
        ok
    catch
        return createErrorResult("Code execution failed: " + cCatchError)
    done


func analyzeCode cCode
    try
        cAnalysis = "Code Analysis Report:" + nl + nl
        aLines = str2list(cCode)
        nLines = len(aLines)
        cAnalysis += "Lines of code: " + nLines + nl

        nFunctions = 0
        nClasses = 0
        for cLine in aLines
            cTrimmedLine = trim(cLine)
            if substr(cTrimmedLine, "func ")
                nFunctions++
            ok
            if substr(cTrimmedLine, "class ")
                nClasses++
            ok
        next

        cAnalysis += "Functions: " + nFunctions + nl
        cAnalysis += "Classes: " + nClasses + nl + nl
        cAnalysis += "Potential Issues:" + nl
        nIssues = 0

        nOpenBraces = 0
        nCloseBraces = 0
        for cLine in aLines
            nOpenBraces += countSubstring(cLine, "{")
            nCloseBraces += countSubstring(cLine, "}")
        next

        if nOpenBraces != nCloseBraces
            cAnalysis += "- Unbalanced braces detected" + nl
            nIssues++
        ok

        bHasMain = false
        for cLine in aLines
            if substr(trim(cLine), "func main")
                bHasMain = true
                exit
            ok
        next

        if not bHasMain and nLines > 5
            cAnalysis += "- No main() function found" + nl
            nIssues++
        ok

        if nIssues = 0
            cAnalysis += "- No obvious issues detected" + nl
        ok

        return createSuccessResult(cAnalysis)
    catch
        return createErrorResult("Code analysis failed: " + cCatchError)
    done


func formatCode cCode
    try
        aLines = str2list(cCode)
        aFormattedLines = []
        nIndentLevel = 0

        for cLine in aLines
            cTrimmedLine = trim(cLine)

            if substr(cTrimmedLine, "}") or
               substr(cTrimmedLine, "next") or
               substr(cTrimmedLine, "ok") or
               substr(cTrimmedLine, "done")
                nIndentLevel--
                if nIndentLevel < 0  nIndentLevel = 0  ok
            ok

            cIndent = copy("    ", nIndentLevel)
            if len(cTrimmedLine) > 0
                aFormattedLines + cIndent + cTrimmedLine
            else
                aFormattedLines + ""
            ok

            if substr(cTrimmedLine, "{") or
               substr(cTrimmedLine, "for ") or
               substr(cTrimmedLine, "while ") or
               substr(cTrimmedLine, "if ") or
               substr(cTrimmedLine, "func ") or
               substr(cTrimmedLine, "class ") or
               substr(cTrimmedLine, "try")
                nIndentLevel++
            ok
        next

        cFormattedCode = list2str(aFormattedLines)
        return createSuccessResult("Formatted code:" + nl + cFormattedCode)
    catch
        return createErrorResult("Code formatting failed: " + cCatchError)
    done
