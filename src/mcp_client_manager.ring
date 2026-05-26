# ===================================================================
# MCP Client Manager - Integration with Ring_MCP_SDK
# ===================================================================
aMCP_FetchedTools_Bridge = []

class MCPClientManager

    aClients = []
    
    # ===================================================================
    # Initialize Manager
    # ===================================================================
    func init()
        # Initialized
        
    # ===================================================================
    # Connect via STDIO
    # ===================================================================
    func connectStdio(cServerName, cCommand, aArgs)
        oClient = new MCPClient {
            name = cServerName
            version = "3.0.0"
        }
        
        oTransport = new StdioClientTransport {
            Command = cCommand
            Args = aArgs
        }
        
        oClient.oTransport = ref(oTransport)
        oClient.oTransport.run(oClient)
        
        # Give the child process time to start its stdin loop
        # Without this, we send initialize before the child is ready
        sleep(2)
        
        # Drain any startup output (stderr messages, etc.) before sending
        try
            oTransport.processPendingOutput()
        catch done
        
        # Initialize connection (with error handling)
        try
            oClient.initialize()
            # Mandatory MCP notification after initialize response
            if lower(cServerName) != "ring-mcp"
                oClient.send_message(oClient.get_router().notify("notifications/initialized", []))
            ok
        catch
            see "  [-] MCP initialize failed: " + cCatchError + nl
            return []
        done
        
        sleep(1.0)
        
        aClients + oClient
        
        try
            return fetchTools(oClient)
        catch
            see "  [-] MCP fetchTools failed: " + cCatchError + nl
            return []
        done
        
    # ===================================================================
    # Connect via HTTP
    # ===================================================================
    func connectHttp(cServerName, cUrl)
        oClient = new MCPClient {
            name = cServerName
            version = "3.0.0"
        }
        
        oTransport = new HttpClientTransport {
            Url = cUrl
        }
        
        oClient.oTransport = ref(oTransport)
        oClient.oTransport.run(oClient)
        
        # Initialize connection
        oClient.initialize()
        
        sleep(0.5)
        
        aClients + oClient
        
        return fetchTools(oClient)
        
    # ===================================================================
    # Fetch Tools from Server
    # ===================================================================
    func fetchTools(oClient)
        
        
        oHandler = new ToolsListHandler {
            id = oClient.nNextRequestId
        }
        
        nId = oClient.nNextRequestId
        oClient.nNextRequestId++
        oClient.add_pending_request(oHandler)
        
        aMsg = oClient.get_router().request(nId, "tools/list", [])
        oClient.send_message(aMsg)
        
        # Wait for response (timeout 5 seconds)
        nWait = 0
        while not oHandler.bDone and nWait < 500
            sleep(0.01)
            nWait++
        end
        
        # Use the bridge if the handler is empty (Scoping workaround)
        aRawTools = oHandler.aTools
        if islist(aRawTools) and len(aRawTools) = 0
            try
                aRawTools = aMCP_FetchedTools_Bridge
                aMCP_FetchedTools_Bridge = [] # Clear it
            catch done
        ok
        
        # Bind tools to client reference for later execution
        aMappedTools = []
        if islist(aRawTools)
            if len(aRawTools) > 0
                for oTool in aRawTools
                    Add(aMappedTools, [
                        :client = oClient,
                        :toolDef = oTool
                    ])
                next
            ok
        ok
        
        return aMappedTools

    # ===================================================================
    # Call Tool on Server
    # ===================================================================
    func callTool(oClient, cToolName, aArgs)
        
                
        oHandler = new ToolCallHandler {
            id = oClient.nNextRequestId
        }
        
        nId = oClient.nNextRequestId
        oClient.nNextRequestId++
        oClient.add_pending_request(oHandler)
        
        aMsg = oClient.get_router().request(nId, "tools/call", [
            :name = cToolName,
            :arguments = aArgs
        ])
        oClient.send_message(aMsg)
        
        # Wait for response (timeout 30 seconds for long tools)
        nWait = 0
        while not oHandler.bDone and nWait < 3000
            sleep(0.01)
            nWait++
        end
        
        # Use injected result from oClient
        if isattribute(oClient, "cTempResult")
            cResult = oClient.cTempResult
            bIsError = oClient.bTempError
            
            # Reset injection for next call
            oClient.cTempResult = ""
            oClient.bTempError = false
            
            return [not bIsError, cResult]
        ok
        
        if not oHandler.bDone
            return [false, "Tool execution timed out on MCP server."]
        ok
        
        return [not oHandler.bIsError, oHandler.cResult]



class ToolsListHandler
            id
            bDone = false
            aTools = []
            func callback aRes
                # see "DEBUG: MCP Response -> " + mcp_json_encode(aRes) + nl
                
                if not islist(aRes) return ok
                
                # Check for result object
                oResult = NULL
                for item in aRes
                    if islist(item) and len(item) >= 2 and item[1] = "result"
                        oResult = item[2]
                        exit
                    ok
                next
                
                if islist(oResult)
                    for item in oResult
                        if islist(item) and len(item) >= 2 and item[1] = "tools"
                            self.aTools = item[2]
                            aMCP_FetchedTools_Bridge = self.aTools
                            exit
                        ok
                    next
                ok
                self.bDone = true

class ToolCallHandler
            id
            bDone = false
            cResult = ""
            bIsError = false
            func callback aRes
                # Extraction
                oResult = NULL
                oError = NULL
                if islist(aRes)
                    for item in aRes
                        if islist(item) and len(item) >= 2
                            if item[1] = "result" oResult = item[2]
                            elseif item[1] = "error" oError = item[2] ok
                        ok
                    next
                ok
                
                if not isnull(oError)
                    self.bIsError = true
                    self.cResult = "MCP Error: " + mcp_json_encode(oError)
                elseif not isnull(oResult)
                    self.bIsError = false
                    self.cResult = mcp_json_encode(oResult)
                ok
                
                # Injection Bridge
                try
                    addattribute(Client, "cTempResult")
                    addattribute(Client, "bTempError")
                    Client.cTempResult = self.cResult
                    Client.bTempError = self.bIsError
                catch done
                
                self.bDone = true
