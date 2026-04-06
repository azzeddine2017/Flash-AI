class DataLogger
    func getProjectSize()
        totalSize = 0
        files = dir(".")
        for file in files
            if file[2] = 0
                totalSize += filesize(file[1])
            ok
        next
        return totalSize
    func generateReport()
        return "Project Size: " + getProjectSize() + " bytes."
