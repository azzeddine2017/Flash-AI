# ===================================================================
# AI Assistant Class - Handles intelligent chat responses (Legacy)
# NOTE: This is the offline/fallback assistant. The primary AI
#       integration is done via SmartAgent + AIClient.
# ===================================================================

class AIAssistant
    
    # Private properties
    aChatHistory = []
    
    # ===================================================================
    # Constructor
    # ===================================================================
    func init()
        see "AIAssistant initialized." + nl
    
    # ===================================================================
    # Chat with AI (WebView callback)
    # ===================================================================
    func chatWithAI(id, req, oWebView)
        try
            aParamsRaw = json2list(req)
            if type(aParamsRaw) = "LIST" and len(aParamsRaw) >= 1
                aParams = aParamsRaw[1]
            else
                aParams = []
            ok
            cMessage = aParams[1]
            cCurrentCode = aParams[2]
            
            # Process the AI chat request
            cResponse = processAIChat(cMessage, cCurrentCode)
            
            # Add to chat history
            aChatHistory + [cMessage, cResponse]
            
            cJsonResponse = list2json([cResponse])
            oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonResponse)
            see "AI chat processed: " + cMessage + nl
            
        catch
            see "Error in AI chat: " + cCatchError + nl
            cErrorMsg = "Sorry, an error occurred while processing your request. Please try again."
            cJsonError = list2json([cErrorMsg])
            oWebView.wreturn(id, WEBVIEW_ERROR_OK, cJsonError)
        done
    
    # ===================================================================
    # Process AI Chat
    # ===================================================================
    func processAIChat(cMessage, cCurrentCode)
        cResponse = ""
        cLowerMessage = lower(cMessage)
        
        # Analyze the message and provide appropriate response
        if substr(cLowerMessage, "help")
            cResponse = getHelpResponse()
            
        elseif substr(cLowerMessage, "error") or substr(cLowerMessage, "bug")
            cResponse = getErrorHelpResponse(cCurrentCode)
            
        elseif substr(cLowerMessage, "how")
            cResponse = getHowToResponse(cMessage)
            
        elseif substr(cLowerMessage, "example") or substr(cLowerMessage, "sample")
            cResponse = getExampleResponse(cMessage)
            
        elseif substr(cLowerMessage, "optimize") or substr(cLowerMessage, "improve")
            cResponse = getOptimizationResponse(cCurrentCode)
            
        elseif substr(cLowerMessage, "explain")
            cResponse = getExplanationResponse(cCurrentCode)
            
        else
            cResponse = getGeneralResponse(cMessage, cCurrentCode)
        ok
        
        return cResponse
    
    # ===================================================================
    # Help Response
    # ===================================================================
    func getHelpResponse()
        return "Hello! I'm your Ring programming assistant. I can help you with:" + nl +
               "  - Explaining Ring code" + nl +
               "  - Fixing errors and bugs" + nl +
               "  - Providing code examples" + nl +
               "  - Optimizing your code" + nl +
               "  - Answering programming questions" + nl +
               "  - Suggesting solutions" + nl + nl +
               "Type your question or ask for specific help!"
    
    # ===================================================================
    # Error Help Response
    # ===================================================================
    func getErrorHelpResponse(cCode)
        cResponse = "Let me help you fix the errors:" + nl + nl
        
        if len(cCode) > 0
            # Basic error checking
            if not substr(cCode, "func main")
                cResponse += "  - Make sure your program has a main() function" + nl
            ok
            
            nOpenBraces = countSubstring(cCode, "{")
            nCloseBraces = countSubstring(cCode, "}")
            if nOpenBraces != nCloseBraces
                cResponse += "  - Check for unbalanced curly braces { }" + nl
            ok
            
            if not substr(cCode, "load") and not substr(cCode, "import")
                cResponse += "  - You may need to load libraries using 'load'" + nl
            ok
        else
            cResponse += "No code to inspect. Write code first, then ask for help."
        ok
        
        return cResponse
    
    # ===================================================================
    # How To Response
    # ===================================================================
    func getHowToResponse(cMessage)
        cResponse = "Here are some common Ring examples:" + nl + nl
        
        if substr(cMessage, "variable")
            cResponse += "Creating variables:" + nl +
                        'cName = "John"    # String' + nl +
                        "nAge = 25         # Number" + nl +
                        "bActive = true    # Boolean" + nl +
                        "aList = [1,2,3]   # List" + nl
                        
        elseif substr(cMessage, "function")
            cResponse += "Creating functions:" + nl +
                        "func myFunction(param1, param2)" + nl +
                        "    # Function body" + nl +
                        "    return result" + nl
                        
        elseif substr(cMessage, "loop")
            cResponse += "Loops:" + nl +
                        "for i = 1 to 10" + nl +
                        "    see i + nl" + nl +
                        "next" + nl + nl +
                        "while condition" + nl +
                        "    # code" + nl +
                        "end"
        else
            cResponse += "Specify what you want to learn: variables, functions, loops, conditions, classes..."
        ok
        
        return cResponse
    
    # ===================================================================
    # Example Response
    # ===================================================================
    func getExampleResponse(cMessage)
        return "Simple code example:" + nl + nl +
               "# Program to calculate the average" + nl +
               "func main()" + nl +
               "    aNumbers = [10, 20, 30, 40, 50]" + nl +
               "    nSum = 0" + nl +
               "    " + nl +
               "    for nNum in aNumbers" + nl +
               "        nSum += nNum" + nl +
               "    next" + nl +
               "    " + nl +
               "    nAverage = nSum / len(aNumbers)" + nl +
               '    see "Average: " + nAverage + nl' + nl + nl +
               "Would you like an example on a specific topic?"
    
    # ===================================================================
    # Optimization Response
    # ===================================================================
    func getOptimizationResponse(cCode)
        cResponse = "Code optimization suggestions:" + nl + nl
        
        if len(cCode) > 0
            if substr(cCode, "for") and substr(cCode, "see")
                cResponse += "  - Use list2str() instead of a for loop for printing" + nl
            ok
            
            if countSubstring(cCode, "if") > 3
                cResponse += "  - Consider using switch instead of multiple if statements" + nl
            ok
            
            cResponse += "  - Use descriptive variable names" + nl +
                        "  - Break code into small functions" + nl +
                        "  - Add explanatory comments" + nl
        else
            cResponse = "Write code first so I can suggest improvements."
        ok
        
        return cResponse
    
    # ===================================================================
    # Explanation Response
    # ===================================================================
    func getExplanationResponse(cCode)
        if len(cCode) = 0
            return "Write code first so I can explain it."
        ok
        
        cResponse = "Code explanation:" + nl + nl
        aLines = str2list(cCode)
        
        for i = 1 to len(aLines)
            cLine = trim(aLines[i])
            if len(cLine) > 0 and not substr(cLine, "#")
                cResponse += "Line " + i + ": "
                
                if substr(cLine, "func ")
                    cResponse += "Defines a new function"
                elseif substr(cLine, "for ")
                    cResponse += "Starts a loop"
                elseif substr(cLine, "if ")
                    cResponse += "Conditional statement"
                elseif substr(cLine, "see ")
                    cResponse += "Prints text or a variable"
                elseif substr(cLine, "=")
                    cResponse += "Assigns a value to a variable"
                else
                    cResponse += "Executes an operation"
                ok
                
                cResponse += nl
            ok
        next
        
        return cResponse
    
    # ===================================================================
    # General Response
    # ===================================================================
    func getGeneralResponse(cMessage, cCurrentCode)
        return "Thanks for your question! Let me understand your request..." + nl + nl +
               "I can help you with:" + nl +
               "  - Writing Ring code" + nl +
               "  - Explaining programming concepts" + nl +
               "  - Fixing errors" + nl +
               "  - Improving performance" + nl + nl +
               "Please ask a more specific question so I can assist you better."
