func dependency_graph_generator(directory)
    if directory = "" or directory = "."
        directory = CurrentDir()
    ok
    
    if not dirExists(directory)
        return "Error: Invalid directory: " + directory
    ok
    
    cGraph = "Dependency Graph for: " + directory + nl + copy("=", 40) + nl
    cGraph += scan_dependencies_recursive(directory, 0)
    
    return cGraph
ok

func scan_dependencies_recursive(cDir, nDepth)
    cOut = ""
    aFiles = dir(cDir)
    if type(aFiles) != "LIST" return cOut ok
    
    cPrefix = copy("  ", nDepth)
    
    # Process files
    for item in aFiles
        cFile = item[1]
        nType = item[2]
        
        # Skip hidden files
        if left(cFile, 1) = "." loop ok
        
        if nType = 1 # Directory
            cOut += cPrefix + "📁 " + cFile + "/" + nl
            cOut += scan_dependencies_recursive(cDir + "/" + cFile, nDepth + 1)
        elseif nType = 0 and right(lower(cFile), 5) = ".ring"
            cPath = cDir + "/" + cFile
            cContent = read(cPath)
            aLines = str2list(cContent)
            
            aDeps = []
            for cLine in aLines
                cTrim = trim(cLine)
                if left(lower(cTrim), 5) = "load "
                    cDep = trim(substr(cTrim, 6))
                    cDep = substr(cDep, '"', '')
                    cDep = substr(cDep, "'", "")
                    aDeps + cDep
                ok
            next
            
            if len(aDeps) > 0
                cOut += cPrefix + "📄 " + cFile + nl
                for cDep in aDeps
                    cOut += cPrefix + "    🔗 depends on -> " + cDep + nl
                next
            else
                cOut += cPrefix + "📄 " + cFile + " (standalone)" + nl
            ok
        ok
    next
    
    return cOut
ok
