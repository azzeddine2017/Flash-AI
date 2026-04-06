# ===================================================================
# Core Agent - Unified Processing Layer for CLI and GUI
# Provides a single interface for both frontends to interact with
# the SmartAgent, handling common request preprocessing, output
# formatting, and session management.
# ===================================================================



class CoreAgent

    # Components
    oSmartAgent 
    oLogger   

    # Configuration
    cVersion       = "2.0"
    bAutoSave      = true
    nAutoSaveEvery = 5      # Auto-save every N messages
    nMessageCount  = 0

    # Callback interface (set by CLI or GUI)
    oFrontend = null

    # ===================================================================
    # Constructor
    # ===================================================================
    func init
        oLogger = new Logger()
        oLogger.info("CoreAgent layer initialized v" + cVersion)

    # ===================================================================
    # Set the SmartAgent instance
    # ===================================================================
    func setSmartAgent oAgent
        oSmartAgent = oAgent

    # ===================================================================
    # Set the frontend adapter (CLI UIManager or GUI GUIManager)
    # ===================================================================
    func setFrontend oFE
        oFrontend = oFE
        if oSmartAgent != null
            oSmartAgent.setUIManager(oFE)
        ok

    # ===================================================================
    # Process a user message with common pre/post processing
    # This is the unified entry point for both CLI and GUI
    # ===================================================================
    func processMessage cMessage, cExtraContext
        if cMessage = null or trim(cMessage) = ""
            return createResult(false, "", "", "Empty message")
        ok

        oLogger.info("Processing: " + left(cMessage, 80))
        nMessageCount++

        # Pre-process: sanitize but preserve the original intent
        cCleanMessage = trim(cMessage)

        # Build context string
        cContext = ""
        if cExtraContext != null and cExtraContext != ""
            cContext = cExtraContext
        ok
        cContext += "Working Directory: " + CurrentDir() + nl

        # Delegate to SmartAgent
        oResponse = oSmartAgent.processRequest(cCleanMessage, cContext)

        # Post-process the response
        oResult = createResult(
            oResponse[:success],
            oResponse[:message],
            "",
            oResponse[:error]
        )

        # Copy thought if available
        if oResponse[:thought] != null and oResponse[:thought] != ""
            oResult[:thought] = oResponse[:thought]
        ok

        # Copy token info if available
        if oResponse[:total_tokens] != null
            oResult[:total_tokens] = oResponse[:total_tokens]
        ok

        # Auto-save check
        if bAutoSave and (nMessageCount % nAutoSaveEvery) = 0
            try
                oSmartAgent.saveHistory()
                oLogger.debug("Auto-saved session at message " + nMessageCount)
            catch
                oLogger.warn("Auto-save failed: " + cCatchError)
            done
        ok

        oLogger.info("Response generated successfully")
        return oResult

    # ===================================================================
    # Quick tool execution (bypasses AI, runs a tool directly)
    # ===================================================================
    func runTool cToolName, aParams
        if oSmartAgent = null
            return createResult(false, "", "", "SmartAgent not initialized")
        ok

        oLogger.info("Direct tool execution: " + cToolName)

        try
            oToolResult = oSmartAgent.oAgentTools.executeTool(cToolName, aParams)

            # Notify frontend about tool execution
            if oFrontend != null
                try
                    cDetails = ""
                    if len(aParams) > 0
                        cDetails = aParams[1]
                    ok
                    oFrontend.displayToolAction(upper(cToolName), cDetails)
                catch
                done
            ok

            return createResult(
                oToolResult[:success],
                oToolResult[:message],
                "",
                oToolResult[:error]
            )
        catch
            return createResult(false, "", "", "Tool execution failed: " + cCatchError)
        done

    # ===================================================================
    # Session Management (unified for CLI and GUI)
    # ===================================================================
    func newSession
        oSmartAgent.oContextEngine.clearHistory()
        oSmartAgent.cSessionId = oSmartAgent.generateSessionId()
        oSmartAgent.nTotalTokens = 0
        oSmartAgent.oAIClient.resetTokens()
        nMessageCount = 0
        
        # Reset advanced subsystems for clean session
        if oSmartAgent.oTelemetry != null
            oSmartAgent.oTelemetry.reset()
        ok
        if oSmartAgent.oSecurityLayer != null
            oSmartAgent.oSecurityLayer.revoke()
        ok
        oSmartAgent.bSessionAuthorized = false
        
        oLogger.info("New session started: " + oSmartAgent.cSessionId)
        return oSmartAgent.cSessionId

    func saveSession cFormat
        switch lower(cFormat)
            on "json" on ""
                oSmartAgent.saveHistory()
                return APP_PATH("chats/session_" + oSmartAgent.cSessionId + ".json")
            on "txt" on "text"
                cFile = APP_PATH("chats/session_" + oSmartAgent.cSessionId + ".txt")
                oSmartAgent.saveToText(cFile)
                return cFile
            on "md" on "markdown"
                cFile = APP_PATH("chats/session_" + oSmartAgent.cSessionId + ".md")
                oSmartAgent.saveToMD(cFile)
                return cFile
            other
                return ""
        off

    func loadSession cFile
        if oSmartAgent.loadHistory(cFile)
             
            oLogger.info("Session loaded: " + cFile)
            return true
        ok
        return false

    func deleteSession cFile
        if oSmartAgent.deleteSession(cFile)
            oLogger.info("Session deleted: " + cFile)
            return true
        ok
        return false

    func getSessionsList
        return oSmartAgent.getSavedSessions()

    func getSessionsWithPreviews
        aSessions = oSmartAgent.getSavedSessions()
        return oSmartAgent.getSessionsWithPreviews(aSessions)

    # ===================================================================
    # Configuration Management
    # ===================================================================
    func setModel cModel
        oSmartAgent.oAIClient.setModel(cModel)
        oLogger.info("Model changed to: " + cModel)
    ok

    func setProvider cProvider
        result = oSmartAgent.oAIClient.setProvider(cProvider)
        if result
            oLogger.info("Provider changed to: " + cProvider)
        ok
        return result

    func setTemperature nTemp
        oSmartAgent.oAIClient.nTemperature = nTemp

    func setMaxTokens nTokens
        oSmartAgent.oAIClient.nMaxTokens = nTokens

    func setDebugMode bEnabled
        oSmartAgent.setDebugMode(bEnabled)

    func setLanguage cLang
        oSmartAgent.setLanguage(cLang)

    func authorizeSession
        oSmartAgent.setSessionAuthorized(true)
        oLogger.info("Session fully authorized")

    func revokeAuthorization
        oSmartAgent.setSessionAuthorized(false)
        oLogger.info("Session authorization revoked")

    func hasValidAPIKey
        return oSmartAgent.oAIClient.hasValidAPIKey()

    func saveAPIKey cKey
        oSmartAgent.oAIClient.saveAPIKey(cKey)

    # ===================================================================
    # Status & Info Getters
    # ===================================================================
    func getConfig
        cMdl = oSmartAgent.oAIClient.cGeminiModel
        switch oSmartAgent.oAIClient.cCurrentProvider
            on "openai" cMdl = oSmartAgent.oAIClient.cOpenAIModel
            on "claude" cMdl = oSmartAgent.oAIClient.cClaudeModel
            on "openrouter" cMdl = oSmartAgent.oAIClient.cOpenRouterModel
        off
        return [
            ["agent",       oSmartAgent.cAgentName + " v" + oSmartAgent.cAgentVersion],
            ["provider",    oSmartAgent.oAIClient.cCurrentProvider],
            ["model",       cMdl],
            ["temperature", "" + oSmartAgent.oAIClient.nTemperature],
            ["max_tokens",  "" + oSmartAgent.oAIClient.nMaxTokens],
            ["language",    oSmartAgent.cLanguagePreference],
            ["debug",       "" + oSmartAgent.bDebugMode],
            ["session_id",  oSmartAgent.cSessionId],
            ["working_dir", CurrentDir()],
            ["tools_count", "" + len(oSmartAgent.oAgentTools.aAvailableTools)],
            ["messages",    "" + nMessageCount]
        ]

    func getTotalTokens
        return oSmartAgent.nTotalTokens

    func getSessionId
        return oSmartAgent.cSessionId

    func getToolsList
        return oSmartAgent.oAgentTools.aAvailableTools

    func getToolsCount
        return len(oSmartAgent.oAgentTools.aAvailableTools)

    func getConversationHistory
        return oSmartAgent.oContextEngine.aConversationHistory

    # ===================================================================
    # Internal Helpers
    # ===================================================================
    private

    func createResult bSuccess, cMessage, cThought, cError
        return [
            :success      = bSuccess,
            :message      = cMessage,
            :thought      = cThought,
            :error        = cError,
            :total_tokens = 0
        ]
