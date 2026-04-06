func code_refactor_assistant(filename)
    if not fexists(filename)
        return "Error: File not found: " + filename
    ok
    cCode = read(filename)
    aLines = str2list(cCode)
    
    cReport = "Code Refactor Report for: " + filename + nl + nl
    cReport += "Analysis highlights:" + nl
    
    nLongFuncs = 0
    nComplexLines = 0
    
    for i = 1 to len(aLines)
        cLine = trim(aLines[i])
        if substr(cLine, "func ") > 0
            nLinesInFunc = 0
            for j = i + 1 to len(aLines)
                if j > i and (substr(trim(aLines[j]), "func ") > 0 or substr(trim(aLines[j]), "class ") > 0)
                    exit
                ok
                nLinesInFunc++
            next
            if nLinesInFunc > 50
                cReport += "- Function starting at line " + i + " is too long (" + nLinesInFunc + " lines)." + nl
                nLongFuncs++
            ok
        ok
        
        nIndent = 0
        for j = 1 to len(aLines[i])
            if aLines[i][j] = " "
                nIndent++
            elseif aLines[i][j] = char(9)
                nIndent += 4
            else
                exit
            ok
        next
        if nIndent > 16
            nComplexLines++
        ok
    next
    
    if nComplexLines > 0
        cReport += "- Found " + nComplexLines + " lines with deep nesting (possible high cyclomatic complexity)." + nl
    ok
    
    if nLongFuncs = 0 and nComplexLines = 0
        cReport += "- Code looks clean and follows basic standards." + nl
    else
        cReport += nl + "Recommendation: Break down large functions and flatten nested logic." + nl
    ok
    
    return cReport
ok
