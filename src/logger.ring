# ===================================================================
# Logger - Centralized Logging System for FLASH AI
# Supports DEBUG, INFO, WARN, ERROR levels
# ===================================================================

# Log level constants
LOG_DEBUG = 0
LOG_INFO  = 1
LOG_WARN  = 2
LOG_ERROR = 3

class Logger

    # Configuration
    cLogFile    = APP_PATH("logs/flash_ai.log")
    nMinLevel   = LOG_INFO    # Minimum level to log
    bConsoleLog = false       # Also print to console
    nMaxFileSize = 1048576    # 1MB max per log file
    
    func init
        # Ensure logs directory exists - silent on windows
        cLogs = APP_PATH("logs")
        if not dirExists(cLogs)
            makedir(cLogs)
        ok
    
    # ===================================================================
    # Public Logging Methods
    # ===================================================================
    
    func debug cMessage
        writeLog(LOG_DEBUG, "DEBUG", cMessage)
    
    func info cMessage
        writeLog(LOG_INFO, "INFO", cMessage)
    
    func warn cMessage
        writeLog(LOG_WARN, "WARN", cMessage)
    
    func error cMessage
        writeLog(LOG_ERROR, "ERROR", cMessage)
    
    # ===================================================================
    # Set Minimum Log Level
    # ===================================================================
    
    func setLevel nLevel
        nMinLevel = nLevel
    
    func enableConsole bEnable
        bConsoleLog = bEnable
    
    # ===================================================================
    # Core Log Writer
    # ===================================================================
    
    private
    
    func writeLog nLevel, cLevel, cMessage
        if nLevel < nMinLevel return ok
        
        try
            # Check file size for rotation
            if fexists(cLogFile)
                nSize = len(read(cLogFile))
                if nSize > nMaxFileSize
                    rotateLog()
                ok
            ok
            
            # Format: [2026-03-23 12:00:00] [INFO] Message
            cTimestamp = date() + " " + time()
            cLine = "[" + cTimestamp + "] [" + cLevel + "] " + cMessage + nl
            
            # Append to file
            fp = fopen(cLogFile, "a")
            if fp != NULL
                fwrite(fp, cLine)
                fclose(fp)
            ok
            
            # Console output if enabled
            if bConsoleLog
                see cLine
            ok
        catch
            # Silent fail - don't crash if logging fails
        done
    
    # ===================================================================
    # Log Rotation
    # ===================================================================
    
    func rotateLog
        try
            cBackup = cLogFile + "." + date() + ".bak"
            cBackup = substr(cBackup, "/", "-")
            if fexists(cLogFile)
                cContent = read(cLogFile)
                write(cBackup, cContent)
                write(cLogFile, "")
            ok
        catch
            # Silent fail
        done
