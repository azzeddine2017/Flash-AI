
/*
    File: utils/file_manager.ring
    Description: Utility functions for file system operations.
*/

func get_temp_path()
    # Returns the system temporary directory path
    # In Ring, we can use sysget() for environment variables
    if iswindows()
        return sysget("TEMP")
    else
        return "/tmp"
    ok
