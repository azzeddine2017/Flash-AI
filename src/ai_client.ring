# ===================================================================
# AI Client - Advanced API Integration System
# ===================================================================


$g_AIClient_Object = NULL
$g_AIClient_StreamBuffer = ""

func __ai_client_stream_callback cData
    if $g_AIClient_Object != NULL
        $g_AIClient_Object.processStreamChunk(cData)
    ok


class AIClient
    
    # Configuration
    cGeminiAPIKey = ""
    cOpenAIAPIKey = ""
    cClaudeAPIKey = ""
    cOpenRouterAPIKey = ""
    # AIClient initialized with provider: gemini
    cCurrentProvider = "gemini"  # Default provider
    
    cGeminiModel = "gemini-3-flash-preview" # 
    cOpenAIModel = "gpt-4.1"
    cClaudeModel = "claude-3.5-sonnet"
    cOpenRouterModel = "x-ai/grok-4.1-fast:free"

    # API Endpoints
    cGeminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"+cGeminiModel+":generateContent"
    cOpenAIEndpoint = "https://api.openai.com/v1/chat/completions"
    cClaudeEndpoint = "https://api.anthropic.com/v1/messages"
    cOpenRouterEndpoint = "https://openrouter.ai/api/v1/chat/completions"
    
    # Request settings
    nTimeout = 60
    nMaxTokens = 4096
    nTemperature = 0.7
    
    # Streaming
    bStreamMode = false
    cStreamBuffer = ""
    
    # Stats
    nTotalTokens = 0
    
    # Rate Limiting & Reliability
    nRateLimitRPM     = 15      # Max requests per minute (Free tier: 15)
    nLastRequestTime  = 0       # Last request timestamp in clocks
    nMaxRetries       = 3       # Auto-retries with exponential backoff 
    bWaitingLimit     = true    # Enable waiting before requests
    
    # ===================================================================
    # Constructor
    # ===================================================================
    func init()
        $g_AIClient_Object = self
        loadAPIKeys()
        see "AIClient initialized with provider: " + cCurrentProvider + nl

    func addTokens(n)
        nTotalTokens += n

    func resetTokens()
        nTotalTokens = 0

    func setStreamMode(bEnable)
        self.bStreamMode = bEnable

    func processStreamChunk(cChunk)
        # This is called by HTTPClient's WriteCallback
        self.cStreamBuffer += cChunk
        $g_AIClient_StreamBuffer += cChunk
        
        # Simple extraction for real-time feedback
        nPos = substr(cChunk, '"text": "')
        if nPos > 0
            cRest = substr(cChunk, nPos + 9)
            nEnd = substr(cRest, '"')
            if nEnd > 0
                cText = left(cRest, nEnd-1)
                cText = substr(cText, "\n", nl)
                cText = substr(cText, '\"', '"')
                see cText
                # Natural typing effect: Add a small delay
                sleep(0.1)
            ok
        ok
    
    
    # ===================================================================
    # Load API Keys from Configuration
    # ===================================================================
    func loadAPIKeys()
        if fexists(APP_PATH("config/api_keys.json"))
            try
                cConfigContent = read(APP_PATH("config/api_keys.json"))
                oConfig = json2list(cConfigContent)
                if type(oConfig) = "LIST" and len(oConfig) > 0
                    oKeys = oConfig
                    if type(oKeys) = "LIST"
                        # Load values using robust getValue
                        oGemini = getValue(oKeys, "gemini", [])
                        if type(oGemini) = "LIST"
                            cGeminiAPIKey = getValue(oGemini, "api_key", "")
                        ok

                        oOpenAI = getValue(oKeys, "openai", [])
                        if type(oOpenAI) = "LIST"
                            cOpenAIAPIKey = getValue(oOpenAI, "api_key", "")
                        ok

                        oClaude = getValue(oKeys, "claude", [])
                        if type(oClaude) = "LIST"
                            cClaudeAPIKey = getValue(oClaude, "api_key", "")
                        ok

                        oOpenRouter = getValue(oKeys, "openrouter", [])
                        if type(oOpenRouter) = "LIST"
                            self.cOpenRouterAPIKey = getValue(oOpenRouter, "api_key", "")
                        ok

                        self.cCurrentProvider = getValue(oKeys, "default_provider", "gemini")
                        # see "[DEBUG] Loaded Provider: " + self.cCurrentProvider + nl
                        self.nMaxTokens       = getValue(oKeys, "max_tokens", 4096)
                        self.nTemperature     = getValue(oKeys, "temperature", 0.7)
                        self.nTimeout         = getValue(oKeys, "timeout", 30)
                        self.nRateLimitRPM    = getValue(oKeys, "rate_limit_rpm", 15)
                        self.nMaxRetries      = getValue(oKeys, "max_retries", 3)
                    else
                        see "Error: Invalid configuration format in config/api_keys.json" + nl
                    ok
                ok
            catch
                see "Warning: Could not load API keys correctly: " + cCatchError + nl
            done
        else
            createDefaultConfig()
        ok

    
    # ===================================================================
    # Create Default Configuration File
    # ===================================================================
    func createDefaultConfig()
        try
            ensureDirectoryExists("config")
            
            cConfigJSON = '{
    "gemini": { "api_key": "' + self.cGeminiAPIKey + '" },
    "openai": { "api_key": "' + self.cOpenAIAPIKey + '" },
    "claude": { "api_key": "' + self.cClaudeAPIKey + '" },
    "openrouter": { "api_key": "' + self.cOpenRouterAPIKey + '" },
    "default_provider": "' + self.cCurrentProvider + '",
    "max_tokens": ' + self.nMaxTokens + ',
    "temperature": ' + self.nTemperature + ',
    "timeout": ' + self.nTimeout + ',
    "rate_limit_rpm": ' + self.nRateLimitRPM + ',
    "max_retries": ' + self.nMaxRetries + '
}'
        write(APP_PATH("config/api_keys.json"), cConfigJSON)
            
            see "Created default configuration file: " + APP_PATH("config/api_keys.json") + nl
            see "Please add your API keys to the configuration file." + nl
            
        catch
            see "Error creating default config: " + cCatchError + nl
        done
    
    # ===================================================================
    # Set API Provider
    # ===================================================================
    func setProvider(cProvider)
        if cProvider = "gemini" or cProvider = "openai" or cProvider = "claude" or cProvider = "openrouter"
            cCurrentProvider = cProvider
            see "AI Provider set to: " + cProvider + nl
            return true
        else
            see "Invalid provider: " + cProvider + nl
            return false
        ok
    func setModel(cModel)
        switch cCurrentProvider
            on "gemini" 
                cGeminiModel = cModel
                cGeminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"+cGeminiModel+":generateContent"
            on "openai" cOpenAIModel = cModel
            on "claude" cClaudeModel = cModel
            on "openrouter" cOpenRouterModel = cModel
        off
        see "AI Model set to: " + cModel + nl
    
    
    # ===================================================================
    # API Key Management
    # ===================================================================
    func hasValidAPIKey()
        cKey = ""
        switch cCurrentProvider
            on "gemini" cKey = cGeminiAPIKey
            on "openai" cKey = cOpenAIAPIKey
            on "claude" cKey = cClaudeAPIKey
            on "openrouter" cKey = cOpenRouterAPIKey
        off
        return (cKey != "" and not substr(lower(cKey), "your_") and len(cKey) > 10)

    func saveAPIKey(cKey)
        switch cCurrentProvider
            on "gemini" cGeminiAPIKey = cKey
            on "openai" cOpenAIAPIKey = cKey
            on "claude" cClaudeAPIKey = cKey
            on "openrouter" cOpenRouterAPIKey = cKey
        off
        
        cConfigJSON = '{
    "gemini": { "api_key": "' + self.cGeminiAPIKey + '" },
    "openai": { "api_key": "' + self.cOpenAIAPIKey + '" },
    "claude": { "api_key": "' + self.cClaudeAPIKey + '" },
    "openrouter": { "api_key": "' + self.cOpenRouterAPIKey + '" },
    "default_provider": "' + self.cCurrentProvider + '",
    "max_tokens": ' + self.nMaxTokens + ',
    "temperature": ' + self.nTemperature + ',
    "timeout": ' + self.nTimeout + ',
    "rate_limit_rpm": ' + self.nRateLimitRPM + ',
    "max_retries": ' + self.nMaxRetries + '
}'
        write(APP_PATH("config/api_keys.json"), cConfigJSON)
    
    # ===================================================================
    # Send Request (Main Entry Point)
    # ===================================================================
    func sendRequest(cMessage)
        return sendChatRequest(cMessage, "", [])

    # ===================================================================
    # Send Chat Request
    # ===================================================================
    func sendChatRequest(cMessage, cSystemPrompt, aContext)
        //try
            switch cCurrentProvider
                on "gemini"
                    return sendGeminiRequest(cMessage, cSystemPrompt, aContext)
                on "openai"
                    return sendOpenAIRequest(cMessage, cSystemPrompt, aContext)
                on "claude"
                    return sendClaudeRequest(cMessage, cSystemPrompt, aContext)
                on "openrouter"
                    return sendOpenRouterRequest(cMessage, cSystemPrompt, aContext)
                other
                    oRes = createErrorResponse("Invalid AI provider: " + cCurrentProvider)
            off

            # Handle Auto-Retry on RESOURCE_EXHAUSTED (Rate Limit)
            if oRes[:success] = false and nMaxRetries > 0
               if substr(lower(oRes[:error]), "resource_exhausted") or substr(lower(oRes[:error]), "429")
                  see "  [!] Rate limit reached. Waiting 10s before auto-retry (1/" + nMaxRetries + ")..." + nl
                  sleep(10)
                  # One-time retry
                  switch cCurrentProvider
                      on "gemini" 
                         oRes = sendGeminiRequestWithTools(cMessage, cSystemPrompt, aContext, "")
                  off
               ok
            ok
            return oRes

        /*catch
            return createErrorResponse("Error in AI request: " + cCatchError)
        done*/
    
    # ===================================================================
    # Send Gemini Request (base version, no tools)
    # ===================================================================
    func sendGeminiRequest(cMessage, cSystemPrompt, aContext)
        return sendGeminiRequestWithTools(cMessage, cSystemPrompt, aContext, "")

    # ===================================================================
    # Send Gemini Request WITH Function Declarations
    # cFuncDeclsJSON = JSON string from AgentTools.getFunctionDeclsJSON()
    # ===================================================================
    func sendGeminiRequestWithTools(cMessage, cSystemPrompt, aContext, cFuncDeclsJSON)
        if self.cGeminiAPIKey = "" or self.cGeminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
            return createSuccessResponse("I am in demo mode. To activate tools, add your API key in config/api_keys.json")
        ok

        cFullPrompt = buildContextualPrompt(cMessage, cSystemPrompt, aContext)
        # Escape for JSON embedding
        cPromptJSON = jsonEscape(cFullPrompt)
        cTempStr = self.nTemperature
        cTokStr  = self.nMaxTokens

        if cFuncDeclsJSON != "" and cFuncDeclsJSON != null and len(cFuncDeclsJSON) > 2
            cRequestJSON = '{"contents":[{"role":"user","parts":[{"text":"' + cPromptJSON + '"}]}],' +
                           '"tools":[{"functionDeclarations":' + cFuncDeclsJSON + '}],' +
                           '"generationConfig":{"temperature":' + cTempStr + ',"maxOutputTokens":' + cTokStr + '}}'
        else
            cRequestJSON = '{"contents":[{"role":"user","parts":[{"text":"' + cPromptJSON + '"}]}],' +
                           '"generationConfig":{"temperature":' + cTempStr + ',"maxOutputTokens":' + cTokStr + '}}'
        ok

        cURL = self.cGeminiEndpoint + "?key=" + self.cGeminiAPIKey
        cResponse = sendHTTPRequest(cURL, cRequestJSON, "POST", ["Content-Type: application/json"])
        oRes = parseGeminiResponseFull(cResponse)
        # Retry logic for Rate Limits during long loops
        if oRes[:success] = false and nMaxRetries > 0
            if substr(lower(oRes[:error]), 'resource_exhausted') or substr(lower(oRes[:error]), '429')
                see '  [!] Rate limit reached. Waiting 12s before auto-retry...' + nl
                sleep(12)
                cResponse = sendHTTPRequest(cURL, cRequestJSON, 'POST', ['Content-Type: application/json'])
                oRes = parseGeminiResponseFull(cResponse)
            ok
        ok
        return oRes

    # ===================================================================
    # Send multi-turn conversation with tools
    # cConvJSON = pre-built JSON array string (NOT a Ring list)
    # cFuncDeclsJSON = JSON string of function declarations
    # ===================================================================
    /*func sendGeminiConversation(cConvJSON, cFuncDeclsJSON)
        if self.cGeminiAPIKey = "" or self.cGeminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
            return createSuccessResponse("I am in demo mode. Add your API key in config/api_keys.json")
        ok
 
        cTempStr = self.nTemperature
        cTokStr  = self.nMaxTokens

        if cFuncDeclsJSON != "" and cFuncDeclsJSON != null and len(cFuncDeclsJSON) > 2
            # Ensure contents is wrapped as array if not already
            if left(trim(cConvJSON), 1) != "["
                cConvJSON = "[" + cConvJSON + "]"
            ok
            cRequestJSON = '{"contents":' + cConvJSON + ',' +
                           '"tools":[{"functionDeclarations":' + cFuncDeclsJSON + '}],' +
                           '"generationConfig":{"temperature":' + cTempStr + ',"maxOutputTokens":' + cTokStr + '}}'
        else
            if left(trim(cConvJSON), 1) != "["
                cConvJSON = "[" + cConvJSON + "]"
            ok
            cRequestJSON = '{"contents":' + cConvJSON + ',' +
                           '"generationConfig":{"temperature":' + cTempStr + ',"maxOutputTokens":' + cTokStr + '}}'
        ok

        cURL = self.cGeminiEndpoint + "?key=" + self.cGeminiAPIKey
        cResponse = sendHTTPRequest(cURL, cRequestJSON, "POST", ["Content-Type: application/json"])
        oRes = parseGeminiResponseFull(cResponse)
        # Retry logic for Rate Limits during long loops
        if oRes[:success] = false and self.nMaxRetries > 0
            if substr(lower(oRes[:error]), 'resource_exhausted') or substr(lower(oRes[:error]), '429') or substr(lower(oRes[:error]), 'quota')
                nAttempt = 1
                while nAttempt <= self.nMaxRetries
                    retryWithBackoff(nAttempt)
                    cResponse = sendHTTPRequest(cURL, cRequestJSON, 'POST', ['Content-Type: application/json'])
                    oRes = parseGeminiResponseFull(cResponse)
                    if oRes[:success]  exit  ok
                    nAttempt++
                end
            ok
        ok
        return oRes
    */

    # ===================================================================
    # Send multi-turn conversation with tools (Advanced Reliability Ver)
    # ===================================================================
    func sendGeminiConversation(cConvJSON, cFuncDeclsJSON)
        if self.cGeminiAPIKey = "" or self.cGeminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
            return createSuccessResponse("I am in demo mode. Add your API key in config/api_keys.json")
        ok
 
        cTempStr = self.nTemperature
        cTokStr  = self.nMaxTokens

        # بناء الطلب JSON
        if cFuncDeclsJSON != "" and cFuncDeclsJSON != null and len(cFuncDeclsJSON) > 2
            if left(trim(cConvJSON), 1) != "[" cConvJSON = "[" + cConvJSON + "]" ok
            cRequestJSON = '{"contents":' + cConvJSON + ',' +
                           '"tools":[{"functionDeclarations":' + cFuncDeclsJSON + '}],' +
                           '"generationConfig":{"temperature":' + cTempStr + ',"maxOutputTokens":' + cTokStr + '}}'
        else
            if left(trim(cConvJSON), 1) != "[" cConvJSON = "[" + cConvJSON + "]" ok
            cRequestJSON = '{"contents":' + cConvJSON + ',' +
                           '"generationConfig":{"temperature":' + cTempStr + ',"maxOutputTokens":' + cTokStr + '}}'
        ok

        cURL = self.cGeminiEndpoint + "?key=" + self.cGeminiAPIKey
        
        # --- المحاولة الأولى ---
        cResponse = sendHTTPRequest(cURL, cRequestJSON, "POST", ["Content-Type: application/json"])
        oRes = parseGeminiResponseFull(cResponse)

        # --- نظام التعافي الذكي (Smart Recovery System) ---
        # سنقوم بإعادة المحاولة في الحالات التالية:
        # 1. أخطاء تجاوز الحصص (429 / Quota)
        # 2. أخطاء الشبكة والوقت المستقطع (Status Code: 0)
        # 3. أخطاء السيرفر المؤقتة (500 / 503)
        
        bNeedRetry = false
        if oRes[:success] = false
            cErr = lower(oRes[:error])
            if substr(cErr, "resource_exhausted") or 
               substr(cErr, "429") or 
               substr(cErr, "quota") or
               substr(cErr, "status code: 0") or     # 🌟 إضافة التعامل مع خطأ الشبكة
               substr(cErr, "timeout")               # 🌟 إضافة التعامل مع انتهاء الوقت
                bNeedRetry = true
            ok
        ok

        if bNeedRetry and self.nMaxRetries > 0
            nAttempt = 1
            while nAttempt <= self.nMaxRetries
                see "  [!] Retrying due to network/rate limit (Attempt " + nAttempt + "/" + self.nMaxRetries + ")..." + nl
                
                # استخدام Exponential Backoff لزيادة وقت الانتظار تدريجياً
                retryWithBackoff(nAttempt) 
                
                cResponse = sendHTTPRequest(cURL, cRequestJSON, "POST", ["Content-Type: application/json"])
                oRes = parseGeminiResponseFull(cResponse)
                
                if oRes[:success] 
                    see "  [+] Recovery successful!" + nl
                    exit 
                ok
                nAttempt++
            end
        ok

        return oRes

    # ===================================================================
    # JSON string escape helper
    # ===================================================================
    # Delegate to shared utility
    func jsonEscape(cStr)
        return jsonEscapeStr(cStr)


    
    # ===================================================================
    # Send OpenAI Request
    # ===================================================================
    func sendOpenAIRequest(cMessage, cSystemPrompt, aContext)
        if self.cOpenAIAPIKey = ""
            return createErrorResponse("OpenAI API key not configured")
        ok
        
        try
            # Build messages array
            aMessages = []
            
            if cSystemPrompt != ""
                aMessages + ["role" = "system", "content" = cSystemPrompt]
            ok
            
            # Add context messages
            if type(aContext) = "LIST" and len(aContext) > 0
                for oContextItem in aContext
                    aMessages + oContextItem
                next
            ok
            
            # Add user message
            aMessages + ["role" = "user", "content" = cMessage]
            
            oRequestData = [
                "model" = self.cOpenAIModel,
                "messages" = aMessages,
                "temperature" = self.nTemperature,
                "max_tokens" = self.nMaxTokens
            ]
            
            cRequestJSON = list2json(oRequestData)
            
            # Send HTTP request
            cResponse = sendHTTPRequest(self.cOpenAIEndpoint, cRequestJSON, "POST", [
                "Content-Type: application/json",
                "Authorization: Bearer " + self.cOpenAIAPIKey
            ])
            
            return parseOpenAIResponse(cResponse)
            
        catch
            return createErrorResponse("OpenAI request failed: " + cCatchError)
        done
    
    # ===================================================================
    # Send Claude Request
    # ===================================================================
    func sendClaudeRequest(cMessage, cSystemPrompt, aContext)
        if cClaudeAPIKey = ""
            return createErrorResponse("Claude API key not configured")
        ok
        
        try
            # Build messages array
            aMessages = []
            
            # Add context messages
            if type(aContext) = "LIST" and len(aContext) > 0
                for oContextItem in aContext
                    aMessages + oContextItem
                next
            ok
            
            # Add user message
            aMessages + ["role" = "user", "content" = cMessage]
            
            oRequestData = [
                "model" = cClaudeModel,
                "max_tokens" = nMaxTokens,
                "temperature" = nTemperature,
                "messages" = aMessages
            ]
            
            if cSystemPrompt != ""
                oRequestData["system"] = cSystemPrompt
            ok
            
            cRequestJSON = list2json(oRequestData)
            
            # Send HTTP request
            cResponse = sendHTTPRequest(cClaudeEndpoint, cRequestJSON, "POST", [
                "Content-Type: application/json",
                "x-api-key: " + cClaudeAPIKey,
                "anthropic-version: 2023-06-01"
            ])
            
            return parseClaudeResponse(cResponse)
            
         catch
            return createErrorResponse("Claude request failed: " + cCatchError)
        done

    # ===================================================================
    # Send OpenRouter Request
    # ===================================================================
    func sendOpenRouterRequest(cMessage, cSystemPrompt, aContext, cToolsJSON)
        if self.cOpenRouterAPIKey = "" or self.cOpenRouterAPIKey = "YOUR_OPENROUTER_API_KEY_HERE"
            return createErrorResponse("OpenRouter API key not configured")
        ok
        
        # Build messages array
        aMessages = []
        if cSystemPrompt != ""
            Add(aMessages, [ ["role", "system"], ["content", cSystemPrompt] ])
        ok
        
        # Add context messages
        if type(aContext) = "LIST" and len(aContext) > 0
            for oContextItem in aContext
                if type(oContextItem) = "LIST"
                    cRole = getValue(oContextItem, "role", "")
                    cContent = getValue(oContextItem, "content", "")
                    
                    if cRole != ""
                        aMsgDict = [ ["role", cRole] ]
                        if cContent != "" Add(aMsgDict, ["content", cContent]) ok
                        
                        cToolCallID = getValue(oContextItem, "tool_call_id", "")
                        if cToolCallID != "" Add(aMsgDict, ["tool_call_id", cToolCallID]) ok
                        
                        aToolCalls = getValue(oContextItem, "tool_calls", [])
                        if type(aToolCalls) = "LIST" and len(aToolCalls) > 0 Add(aMsgDict, ["tool_calls", aToolCalls]) ok
                        
                        cName = getValue(oContextItem, "name", "")
                        if cName != "" Add(aMsgDict, ["name", cName]) ok
                        
                        Add(aMessages, aMsgDict)
                    ok
                ok
            next
        ok
        
        # Add user message ONLY if provided AND not already the last message in context
        if cMessage != ""
            # Check if the last context message is already this user message (avoid duplication)
            bAlreadyInContext = false
            if len(aMessages) > 0
                oLastMsg = aMessages[len(aMessages)]
                if type(oLastMsg) = "LIST"
                    cLastRole = getValue(oLastMsg, "role", "")
                    cLastContent = getValue(oLastMsg, "content", "")
                    if cLastRole = "user" and cLastContent = cMessage
                        bAlreadyInContext = true
                    ok
                ok
            ok
            if not bAlreadyInContext
                Add(aMessages, [ ["role", "user"], ["content", cMessage] ])
            ok
        ok
        
        # Build request JSON manually (safest way to avoid R24/JSON issues)
        cMessagesJSON = jsonEncodeRecursive(aMessages)
        cModelJSON = '"' + self.cOpenRouterModel + '"'
        
        cRequestJSON = '{' +
            '"model":' + cModelJSON + ',' +
            '"messages":' + cMessagesJSON + ',' +
            '"temperature":' + self.nTemperature + ',' +
            '"max_tokens":' + self.nMaxTokens

        # Add tools if provided
        if cToolsJSON != "" and cToolsJSON != null and len(cToolsJSON) > 2
            cRequestJSON += ',"tools":' + cToolsJSON
            cRequestJSON += ',"tool_choice":"auto"'
        ok

        cRequestJSON += '}'
        
        # Send HTTP request
        cResponse = sendHTTPRequest(self.cOpenRouterEndpoint, cRequestJSON, "POST", [
            "Content-Type: application/json",
            "Authorization: Bearer " + self.cOpenRouterAPIKey,
            "HTTP-Referer: https://github.com/ring-lang/ring",
            "X-Title: Flash AI Client (Ring)"
        ])
        
        return parseOpenRouterResponse(cResponse)
    
    # ===================================================================
    # Parse OpenRouter Response (OpenAI-compatible)
    # ===================================================================
    func parseOpenRouterResponse(cResponse)
        if cResponse = "" or cResponse = null
            return createErrorResponse("Empty response from OpenRouter API")
        ok

        # OpenRouter usually returns standard OpenAI format
        cResponse = trim(cResponse)
        try
            aResponseList = json2list(cResponse)
            if type(aResponseList) != "LIST" or len(aResponseList) = 0
                return createErrorResponse("Invalid OpenRouter response format")
            ok
            oData = aResponseList
            
            # --- Check for OpenRouter Errors ---
            oError = getValue(oData, "error", NULL)
            if oError != NULL
               if type(oError) = "STRING" return createErrorResponse("OpenRouter Error: " + oError) ok
               cErrorMsg = getValue(oError, "message", "Unknown API error")
               return createErrorResponse("OpenRouter Error: " + cErrorMsg)
            ok

            # Parse Usage (use nResp* prefix to avoid shadowing class member)
            oUsage = getValue(oData, "usage", [])
            nRespPromptTokens     = getValue(oUsage, "prompt_tokens", 0)
            nRespCandidatesTokens = getValue(oUsage, "completion_tokens", 0)
            nRespTotalTokens      = getValue(oUsage, "total_tokens", 0)
            if nRespTotalTokens = 0 nRespTotalTokens = estimateTokens(cResponse) ok

            # Extract choices
            aChoices = getValue(oData, "choices", [])
            if type(aChoices) = "LIST" and len(aChoices) > 0
                oChoice = aChoices[1]
                oMessage = getValue(oChoice, "message", [])
                cContent = getValue(oMessage, "content", "")
                if type(cContent) = "NULL" cContent = "" ok
                
                # Check for reasoning field (OpenRouter specific)
                cReasoning = getValue(oMessage, "reasoning", "")
                if type(cReasoning) = "NULL" cReasoning = "" ok
                
                # --- NEW: Support Tool Calls (Function Calling) ---
                aToolCalls = getValue(oMessage, "tool_calls", [])
                if type(aToolCalls) = "LIST" and len(aToolCalls) > 0
                    oToolCall = aToolCalls[1]
                    oFunction = getValue(oToolCall, "function", [])
                    cFuncName = getValue(oFunction, "name", "")
                    cFuncArgsJSON = getValue(oFunction, "arguments", "{}")
                    cToolCallID   = getValue(oToolCall, "id", "call_" + clock())
                    
                    # Convert arguments string to Ring object
                    oFuncArgs = []
                    try
                        oFuncArgs = json2list(cFuncArgsJSON)
                    catch
                        # Fallback if parsing fails
                    done

                    return [
                        :success = true,
                        :type = "function_call",
                        :function_name = cFuncName,
                        :function_args = oFuncArgs,
                        :tool_call_id  = cToolCallID,
                        :tool_calls    = aToolCalls,
                        :message = trim(cContent),
                        :thought = trim(cReasoning),
                        :error = "",
                        :prompt_tokens = nRespPromptTokens,
                        :candidates_tokens = nRespCandidatesTokens,
                        :total_tokens = nRespTotalTokens,
                        :parts = [],
                        :all_parts = []
                    ]
                ok

                if nRespTotalTokens = 0 
                   nRespTotalTokens = estimateTokens(cContent) + estimateTokens(cReasoning) + 100 # Rough prompt overhead
                ok
                
                return [
                    :success = true,
                    :type = "text",
                    :function_name = "",
                    :function_args = [],
                    :tool_call_id = "",
                    :tool_calls = [],
                    :message = trim(cContent),
                    :thought = trim(cReasoning),
                    :error = "",
                    :prompt_tokens = nRespPromptTokens,
                    :candidates_tokens = nRespCandidatesTokens,
                    :total_tokens = nRespTotalTokens,
                     :parts = [],
                    :all_parts = []
                ]
            ok
        catch
            return createErrorResponse("Failed to parse OpenRouter response: " + cCatchError)
        done
    
    # ===================================================================
    # Build Contextual Prompt
    # ===================================================================
    func buildContextualPrompt(cMessage, cSystemPrompt, aContext)
        cPrompt = ""

        # Add system prompt
        if cSystemPrompt != "" and cSystemPrompt != null
            cPrompt += "System: " + cSystemPrompt + nl + nl
        ok

        # Add context
        if type(aContext) = "LIST" and len(aContext) > 0
            cPrompt += "Context:" + nl
            for oContextItem in aContext
                if type(oContextItem) = "LIST"
                    cRole = getValue(oContextItem, "role", "user")
                    cContent = getValue(oContextItem, "content", "")
                    if cRole != "" and cContent != "" and cRole != null and cContent != null
                        cPrompt += cRole + ": " + cContent + nl
                    ok
                elseif type(oContextItem) = "STRING" and oContextItem != ""
                    cPrompt += oContextItem + nl
                ok
            next
            cPrompt += nl
        ok

        # Add user message
        if cMessage != "" and cMessage != null
            cPrompt += "User: " + cMessage
        ok

        return cPrompt
    
    # ===================================================================
    # Utility Functions
    # ===================================================================
    # Delegate to shared utility
    func getValue(aList, cKey, cDefault)
        return getValueFromList(aList, cKey, cDefault)

    
    func createErrorResponse(cError)
        return [
            :success = false,
            :error = cError,
            :message = "Error connecting to AI service: " + cError
        ]

    func createSuccessResponse(cContent)
        return [
            :success = true,
            :error = "",
            :message = cContent
        ]

    # ===================================================================
    # Send Gemini Streaming Request
    # ===================================================================
    func sendGeminiStreaming(cConversationJSON, cToolsJSON)
        # Preserve original endpoint
        cOrig = self.cGeminiEndpoint
        # Switch to streaming endpoint
        cStreamURL = substr(cOrig, "generateContent", "streamGenerateContent")
        cURL = cStreamURL + "?key=" + self.cGeminiAPIKey
        
        cRequestJSON = '{"contents":' + cConversationJSON + ',' +
                       '"generationConfig":{"temperature":' + self.nTemperature + ',"maxOutputTokens":' + self.nMaxTokens + '}'
        
        if cToolsJSON != "" and cToolsJSON != "[]"
             cRequestJSON += ',"tools":[{"functionDeclarations":' + cToolsJSON + '}]'
        ok
        cRequestJSON += '}'
        
        self.setStreamMode(true)
        cResponse = self.sendHTTPRequest(cURL, cRequestJSON, "POST", ["Content-Type: application/json"])
        self.setStreamMode(false)
        
        # Check if the HTTP request itself returned an error (like 429, 503, etc.)
        if type(cResponse) = "STRING" and len(cResponse) > 0
            if substr(cResponse, '"error"')
                # If we have an error JSON in the response, parse it normally
                return self.parseGeminiResponseFull(cResponse)
            ok
        ok

        # Otherwise, process the accumulated stream buffer
        return self.parseGeminiStreamBuffer(self.cStreamBuffer)
    

    func parseGeminiStreamBuffer(cBuffer)
        # Fallback to global buffer if local is empty (Scope protection)
        if trim(cBuffer) = "" cBuffer = $g_AIClient_StreamBuffer ok
        
        if trim(cBuffer) = ""
            return createErrorResponse("Empty response from Gemini API")
        ok

        try
            aChunks = json2list(cBuffer)
            if type(aChunks) != "LIST" return createErrorResponse("Failed to parse stream buffer") ok
            
            cFullText = ""
            cFullThought = ""
            nTotalT = 0
            oFirstFuncCall = NULL
            aAllParts = []
            
            for oChunk in aChunks
                oUsage = getValue(oChunk, "usageMetadata", [])
                nTotalT = getValue(oUsage, "totalTokenCount", nTotalT)
                
                aCandidates = getValue(oChunk, "candidates", [])
                if len(aCandidates) > 0
                    oCandidate = aCandidates[1]
                    oContent = getValue(oCandidate, "content", [])
                    aParts = getValue(oContent, "parts", [])
                    for oPart in aParts
                        Add(aAllParts, oPart)
                        cFullText += getValue(oPart, "text", "")
                        cFullThought += getValue(oPart, "thought", "")
                        
                        # Capture tool call if present
                        oFunc = getValue(oPart, "functionCall", NULL)
                        if oFunc != NULL and oFirstFuncCall = NULL
                            oFirstFuncCall = oFunc
                        ok
                    next
                ok
            next

            if nTotalT = 0
                nTotalT = estimateTokens(cFullText) + estimateTokens(cFullThought) + 100
            ok

            if oFirstFuncCall != NULL
                return [
                    :success = true,
                    :type = "function_call",
                    :function_name = getValue(oFirstFuncCall, "name", ""),
                    :function_args = getValue(oFirstFuncCall, "args", []),
                    :all_parts = aAllParts,
                    :message = trim(cFullText),
                    :thought = trim(cFullThought),
                    :total_tokens = nTotalT,
                    :error = ""
                ]
            ok

            return [
                :success = true,
                :type = "text",
                :message = trim(cFullText),
                :thought = trim(cFullThought),
                :total_tokens = nTotalT,
                :all_parts = aAllParts,
                :error = ""
            ]
        catch
            return createErrorResponse("Stream parse error: " + cCatchError)
        done
    

    # ===================================================================
    # HTTP Request Function - Using SimpleHTTPClient
    # ===================================================================
    func sendHTTPRequest(cURL, cData, cMethod, aHeaders)
        # Optional: Wait to respect Rate Limit RPM settings
        if bWaitingLimit
            nNow = clock()
            if nLastRequestTime > 0
                nElapsed = (nNow - nLastRequestTime) / (clockspersecond())
                nMinGap = 60.0 / nRateLimitRPM
                if nElapsed < nMinGap
                    nWait = nMinGap - nElapsed
                    if nWait > 0.1 sleep(nWait) ok
                ok
            ok
            nLastRequestTime = clock()
        ok

        nRetry = 0
        while nRetry <= self.nMaxRetries
            nRetry++
            try
                # Create HTTP client
                oClient = new HTTPClient()
                oClient.setTimeout(nTimeout)
                oClient.setVerifySSL(false)

                # --- Configure Streaming ---
                if self.bStreamMode
                    $g_AIClient_Object = self
                    self.cStreamBuffer = ""
                    $g_AIClient_StreamBuffer = ""
                    oClient.setWriteCallback("__ai_client_stream_callback")
                ok

                # Send request
                oResponse = NULL
                switch upper(cMethod)
                    on "GET"  oResponse = oClient.getrequest(cURL, aHeaders)
                    on "POST" oResponse = oClient.post(cURL, cData, aHeaders)
                    other     oResponse = oClient.request(cMethod, cURL, aHeaders, cData)
                off

                oClient.cleanup()

                if oResponse != NULL
                    self.checkRateLimits(oResponse[:headers])
                    
                    cContent = "" + oResponse[:content]
                    if oResponse[:success] and trim(cContent) != ""
                        return oResponse[:content]
                    ok
                    
                    # Error handling with retry logic for Gemini INTERNAL or Empty response
                    if substr(cContent, '"INTERNAL"') or substr(cContent, '"503"') or substr(cContent, '"RESOURCE_EXHAUSTED"') or oResponse[:error] != "" or trim(cContent) = ""
                        if nRetry <= self.nMaxRetries
                            # Increase wait time for quota issues
                            nWaitTime = 2 * nRetry
                            if substr(cContent, '"RESOURCE_EXHAUSTED"') nWaitTime = 10 ok
                            sleep(nWaitTime)
                            loop
                        ok
                    ok

                    if trim(cContent) != "" return cContent ok
                ok
            catch
                if nRetry > self.nMaxRetries return "" ok
            done
        end
        return ""

    # ===================================================================
    # Dynamic Rate Limit Detection
    # ===================================================================
    func checkRateLimits(aHeaders)
        for cHeader in aHeaders
            cLower = lower(cHeader)
            if substr(cLower, "x-ratelimit-remaining")
                # Found rate limit info, we could adjust nRateLimitRPM here
                # For now, just log if it's getting low
                aParts = split(cHeader, ":")
                if len(aParts) >= 2
                    nRemaining = 0 + trim(aParts[2])
                    if nRemaining < 5
                        see "  [!] Warning: AI Rate limit low (" + nRemaining + " remaining)" + nl
                    ok
                ok
            elseif substr(cLower, "retry-after")
                # Server is telling us how long to wait
                aParts = split(cHeader, ":")
                if len(aParts) >= 2
                    see "  [!] Server requested wait (Retry-After): " + aParts[2] + "s" + nl
                ok
            ok
        next


    # ===================================================================
    # Parse Gemini Response (FULL — detects text AND functionCall)
    # Returns extended response with :type field:
    #   :type = "text"  → :message has the answer
    #   :type = "function_call" → :function_name and :function_args are set
    # ===================================================================
    func parseGeminiResponseFull(cResponse)
        if cResponse = "" or cResponse = null
            return createErrorResponse("Empty response from Gemini API")
        ok

        if substr(cResponse, "curl:")
            return createErrorResponse("Network error: " + cResponse)
        ok

        aResponseRaw = json2list(cResponse)
        if type(aResponseRaw) != "LIST" or len(aResponseRaw) = 0
            return createErrorResponse("Invalid Gemini response format: " + left(cResponse, 200))
        ok
        
        # Smart detection: Is it a flat object list or wrapped in another list?
        if type(aResponseRaw[1]) = "LIST" and len(aResponseRaw[1]) = 2 and type(aResponseRaw[1][1]) = "STRING"
            oResponse = aResponseRaw   # The list is the object itself
        else
            oResponse = aResponseRaw[1] # The object is inside the first element
        ok

        # Extract usage metadata (use nResp* prefix to avoid shadowing class member)
        oUsage = getValue(oResponse, "usageMetadata", [])
        nRespPromptTokens     = getValue(oUsage, "promptTokenCount", 0)
        nRespCandidatesTokens = getValue(oUsage, "candidatesTokenCount", 0)
        nRespTotalTokens      = getValue(oUsage, "totalTokenCount", 0)
        if nRespTotalTokens = 0 nRespTotalTokens = estimateTokens(cResponse) ok

        # Handle API Error Object
        oError = getValue(oResponse, "error", NULL)
        if oError != NULL
            if type(oError) = "STRING"
                return createErrorResponse("Gemini API error: " + oError)
            else
                cErrorMsg = getValue(oError, "message", "Unknown error")
                cStatus = getValue(oError, "status", "")
                return createErrorResponse("Gemini API error [" + cStatus + "]: " + cErrorMsg)
            ok
        ok

        # Extract candidates
        aCandidates = getValue(oResponse, "candidates", [])
        if type(aCandidates) != "LIST" or len(aCandidates) = 0
            return createErrorResponse("No candidates in Gemini response")
        ok

        oCandidate = aCandidates[1]
        oContent = getValue(oCandidate, "content", [])
        aParts = getValue(oContent, "parts", [])

        if type(aParts) != "LIST" or len(aParts) = 0
            return createErrorResponse("No parts in Gemini response content")
        ok

        # Collect information from all parts
        cTotalText = ""
        cTotalThought = ""
        oFirstFuncCall = NULL

        for oPart in aParts
            if type(oPart) = "LIST"
                # Check for thought (Reasoning models)
                cT = getValue(oPart, "thought", "")
                if cT != ""
                    cTotalThought += cT + nl
                ok

                # Check for functionCall
                oFuncCall = getValue(oPart, "functionCall", NULL)
                if oFuncCall != NULL and oFirstFuncCall = NULL
                    oFirstFuncCall = oFuncCall
                ok

                # Check for standard text
                cText = getValue(oPart, "text", "")
                if cText != ""
                    cTotalText += cText + nl
                ok
            ok
        next

        if nRespTotalTokens = 0 
            nRespTotalTokens = estimateTokens(cTotalText) + estimateTokens(cTotalThought) + 200 # Context overhead
        ok

        # Decide what to return
        if oFirstFuncCall != NULL
            cFuncName = getValue(oFirstFuncCall, "name", "")
            oFuncArgs = getValue(oFirstFuncCall, "args", [])
            return [
                :success = true,
                :type = "function_call",
                :function_name = cFuncName,
                :function_args = oFuncArgs,
                :all_parts = aParts,
                :thought = trim(cTotalThought),
                :message = trim(cTotalText),
                :error = "",
                :prompt_tokens = nRespPromptTokens,
                :candidates_tokens = nRespCandidatesTokens,
                :total_tokens = nRespTotalTokens
            ]
        ok

        if trim(cTotalText) != ""
            return [
                :success = true,
                :type = "text",
                :function_name = "",
                :function_args = [],
                :all_parts = aParts,
                :thought = trim(cTotalThought),
                :message = trim(cTotalText),
                :error = "",
                :prompt_tokens = nRespPromptTokens,
                :candidates_tokens = nRespCandidatesTokens,
                :total_tokens = nRespTotalTokens
            ]
        ok

        return createErrorResponse("No usable content in Gemini response: " + left(cResponse, 500))

    # ===================================================================
    # Parse Gemini Response (legacy — text only, for backward compat)
    # ===================================================================
    func parseGeminiResponse(cResponse)
        oFull = parseGeminiResponseFull(cResponse)
        return oFull


    # ===================================================================
    # Parse OpenAI Response
    # ===================================================================
    func parseOpenAIResponse(cResponse)
        try
            oResponse = json2list(cResponse)
            if type(oResponse) = "LIST" and len(oResponse) > 0
                oData = oResponse[1]
                # Check for error
                if find(oData, "error")
                    oError = getValue(oData, "error", [])
                    cErrorMsg = getValue(oError, "message", "Unknown error")
                    return createErrorResponse("OpenAI API error: " + cErrorMsg)
                ok
                # Extract usage
                oUsage = getValue(oData, "usage", [])
                nTotalT = getValue(oUsage, "total_tokens", 0)
                if nTotalT = 0 nTotalT = estimateTokens(cResponse) ok

                # Extract content
                aChoices = getValue(oData, "choices", [])
                if type(aChoices) = "LIST" and len(aChoices) > 0
                    oChoice = aChoices[1]
                    oMessage = getValue(oChoice, "message", [])
                    cContent = getValue(oMessage, "content", "")
                    
                    if nTotalT = 0 nTotalT = estimateTokens(cContent) + 150 ok

                    return [
                        :success = true,
                        :message = cContent,
                        :total_tokens = nTotalT,
                        :error = ""
                    ]
                ok
            ok
            return createErrorResponse("Invalid OpenAI response format")
        catch
            return createErrorResponse("Failed to parse OpenAI response: " + cCatchError)
        done

    # ===================================================================
    # Parse Claude Response
    # ===================================================================
    func parseClaudeResponse(cResponse)
        try
            oResponse = json2list(cResponse)
            if type(oResponse) = "LIST" and len(oResponse) > 0
                oData = oResponse[1]
                # Check for error
                if find(oData, "error")
                    oError = getValue(oData, "error", [])
                    cErrorMsg = getValue(oError, "message", "Unknown error")
                    return createErrorResponse("Claude API error: " + cErrorMsg)
                ok
                # Extract usage
                oUsage = getValue(oData, "usage", [])
                nInput = getValue(oUsage, "input_tokens", 0)
                nOutput = getValue(oUsage, "output_tokens", 0)
                nTotalT = nInput + nOutput
                if nTotalT = 0 nTotalT = estimateTokens(cResponse) ok

                # Extract content
                aContent = getValue(oData, "content", [])
                if type(aContent) = "LIST" and len(aContent) > 0
                    oContentItem = aContent[1]
                    cText = getValue(oContentItem, "text", "")
                    
                    if nTotalT = 0 nTotalT = estimateTokens(cText) + 200 ok

                    return [
                        :success = true,
                        :message = cText,
                        :total_tokens = nTotalT,
                        :error = ""
                    ]
                ok
            ok
            return createErrorResponse("Invalid Claude response format")
        catch
            return createErrorResponse("Failed to parse Claude response: " + cCatchError)
        done

    # ===================================================================
    # Extract Thoughts from parts list
    # ===================================================================
    func extractThoughts(aParts)
        cThoughts = ""
        for oPart in aParts
            if type(oPart) = "LIST"
                # Gemini 2.0 Thinking models use 'thought' or 'text' with thought:true
                cT = getValue(oPart, "thought", "")
                if cT != ""
                    cThoughts += cT + nl
                ok
            ok
        next
        return trim(cThoughts)
