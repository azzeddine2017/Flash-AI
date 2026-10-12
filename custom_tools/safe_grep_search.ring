
func safe_grep_search pattern, directory
    # Simply listing files and checking content
    files = dir(directory)
    found = []
    for item in files
        if item[1] != "." and item[1] != ".."
            path = directory + "/" + item[1]
            if item[2] = 0 # Is a file
                content = read(path)
                if substr(content, pattern) > 0
                    add(found, path)
                ok
            ok
        ok
    next
    return list2json(found)
