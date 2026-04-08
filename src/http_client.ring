# ===================================================================
# HTTP Client Module
# ===================================================================


class HTTPClient

    # Client properties
    curl = NULL
    bVerbose = false
    
    # Default settings
    cUserAgent = "-HTTPClient/1.0"
    nTimeout = 30
    bFollowRedirects = true
    bVerifySSL = false
    cCookieFile = APP_PATH("_cookies.txt")
    
    # Default headers
    aDefaultHeaders = [
        "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language: en-US,en;q=0.5",
        "Accept-Encoding: gzip, deflate",
        "Connection: keep-alive",
        "Upgrade-Insecure-Requests: 1"
    ]
    
    /*
    Constructor
    */
    func init
        initializeCurl()
    
    /*
    Initialize libcurl handle
    */
    func initializeCurl
        curl = curl_easy_init()
        if curl = NULL
            return
        ok

        # Basic settings
        curl_easy_setopt(curl, CURLOPT_USERAGENT, cUserAgent)
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, nTimeout)
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1)
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0)
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0)
        curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cCookieFile)
        curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cCookieFile)
    
    /*
    Cleanup resources
    */
    func cleanup
        if curl != NULL
            curl_easy_cleanup(curl)
            curl = NULL
        ok
    
    /*
    Set User Agent
    @param cAgent - User Agent string
    */
    func setUserAgent cAgent
        cUserAgent = cAgent
        if curl != NULL
            curl_easy_setopt(curl, CURLOPT_USERAGENT, cUserAgent)
        ok

    /*
    Set connection timeout
    @param nSeconds - Timeout in seconds
    */
    func setTimeout nSeconds
        nTimeout = nSeconds
        if curl != NULL
            curl_easy_setopt(curl, CURLOPT_TIMEOUT, nTimeout)
        ok

    /*
    Enable/disable redirect following
    @param bEnable - true to enable, false to disable
    */
    func setFollowRedirects bEnable
        bFollowRedirects = bEnable
        if curl != NULL
            nValue = iif(bEnable, 1, 0)
            curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, nValue)
        ok

    /*
    Enable/disable SSL certificate verification
    @param bEnable - true to enable, false to disable
    */
    func setVerifySSL bEnable
        bVerifySSL = bEnable
        if curl != NULL
            nPeerValue = iif(bEnable, 1, 0)
            nHostValue = iif(bEnable, 2, 0)
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, nPeerValue)
            curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, nHostValue)
        ok

    /*
    Set cookie file path
    @param cFile - Path to cookie file
    */
    func setCookieFile cFile
        cCookieFile = cFile
        if curl != NULL
            curl_easy_setopt(curl, CURLOPT_COOKIEJAR, cCookieFile)
            curl_easy_setopt(curl, CURLOPT_COOKIEFILE, cCookieFile)
        ok

    /*
    Enable/disable verbose mode
    @param bEnable - true to enable, false to disable
    */
    func setVerbose bEnable
        bVerbose = bEnable
        if curl != NULL
            nValue = iif(bEnable, 1, 0)
            curl_easy_setopt(curl, CURLOPT_VERBOSE, nValue)
        ok
    
    /*
    Set custom headers
    @param aHeaders - List of header strings
    */
    func setHeaders aHeaders
        if curl = NULL
            return
        ok
        
        # Build header list
        headerList = NULL
        for cHeader in aHeaders
            headerList = curl_slist_append(headerList, cHeader)
        next
        
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headerList)
        
        if bVerbose
            ?  "[ debug ] Set " + len(aHeaders) + " custom headers"
        ok
    
    /*
    Send an HTTP request
    @param cMethod  - Request method (GET, POST, PUT, DELETE, HEAD)
    @param URL      - Target URL
    @param aHeaders - Custom headers
    @param cData    - Request body data
    @return Response object
    */
    func request cMethod, URL, aHeaders, cData
        if curl = NULL
            return createErrorResponse("Internal HTTP error: Handle is null")
        ok
        
        # Set URL
        curl_easy_setopt(curl, CURLOPT_URL, URL)
        
        # Set request method
        switch upper(cMethod)
            on "GET"
                curl_easy_setopt(curl, CURLOPT_HTTPGET, 1)
            on "POST"
                curl_easy_setopt(curl, CURLOPT_POST, 1)
                if cData != NULL and len(cData) > 0
                    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, cData)
                ok
            on "PUT"
                curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "PUT")
                if cData != NULL and len(cData) > 0
                    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, cData)
                ok
            on "DELETE"
                curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "DELETE")
            on "HEAD"
                curl_easy_setopt(curl, CURLOPT_NOBODY, 1)
            other
                curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, cMethod)
        off
        
        # Set headers
        if aHeaders != NULL and len(aHeaders) > 0
            setHeaders(aHeaders)
        else
            setHeaders(aDefaultHeaders)
        ok
        
        # Send request and get response
        try
            cResponse = curl_easy_perform_silent(curl)
            # Get response info
            nResponseCode = curl_getResponseCode(curl)
            nContentLength = curl_getContentLength(curl)
            
            # Create response object
            return createResponse(nResponseCode, cResponse, nContentLength)
            
        catch
            return createErrorResponse("Request execution failed: " + cCatchError)
        done

    
    /*
    Create a response object
    */
    func createResponse nCode, cContent, nLength
        return [
            :status_code = nCode,
            :content = cContent,
            :content_length = nLength,
            :success = (nCode >= 200 and nCode < 300),
            :headers = parseResponseHeaders(cContent)
        ]
    
    /*
    Create an error response object
    */
    func createErrorResponse cError
        return [
            :status_code = 0,
            :content = "",
            :content_type = "",
            :content_length = 0,
            :url = "",
            :success = false,
            :error = cError,
            :headers = []
        ]
    
    /*
    Parse response headers (simplified)
    */
    func parseResponseHeaders cContent
        return []
    
    /*
    Send a GET request
    @param cURL     - Target URL
    @param aHeaders - Optional custom headers
    @return Response object
    */
    func getrequest cURL, aHeaders
        return request("GET", cURL, aHeaders, NULL)
    
    /*
    Send a POST request
    @param cURL     - Target URL
    @param cData    - Request body
    @param aHeaders - Optional custom headers
    @return Response object
    */
    func post cURL, cData, aHeaders
        return request("POST", cURL, aHeaders, cData)
    
    /*
    Send a PUT request
    @param cURL     - Target URL
    @param cData    - Request body
    @param aHeaders - Optional custom headers
    @return Response object
    */
    func putrequest cURL, cData, aHeaders
        return request("PUT", cURL, aHeaders, cData)
    
    /*
    Send a DELETE request
    @param cURL     - Target URL
    @param aHeaders - Optional custom headers
    @return Response object
    */
    func delete cURL, aHeaders
        return request("DELETE", cURL, aHeaders, NULL)
    
    /*
    Send a HEAD request
    @param cURL     - Target URL
    @param aHeaders - Optional custom headers
    @return Response object
    */
    func head cURL, aHeaders
        return request("HEAD", cURL, aHeaders, NULL)
    
    /*
    Download a file from URL
    @param cURL      - Source URL
    @param cFilePath - Local file path to save to
    @return true if successful, false otherwise
    */
    func downloadFile cURL, cFilePath
        see "[ info ] Downloading file from: " + cURL + " to: " + cFilePath + nl
        
        try
            # Open file for writing
            fp = fopen(cFilePath, "wb")
            if fp = NULL
                see "[ error ] Failed to open file for writing: " + cFilePath + nl
                return false
            ok
            
            # Set download options
            curl_easy_setopt(curl, CURLOPT_URL, cURL)
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp)
            
            # Perform download
            curl_easy_perform(curl)
            
            # Close file
            fclose(fp)
            
            # Check download success
            nResponseCode = curl_getResponseCode(curl)
            if nResponseCode = 200
                see "[ info ] File downloaded successfully" + nl
                return true
            else
                see "[ error ] Download failed - Response code: " + nResponseCode + nl
                return false
            ok
            
        catch
            see "[ error ] File download error: " + cCatchError + nl
            return false
        done

    func iif bCondition, cTrue, cFalse
        if bCondition
            return cTrue
        else
            return cFalse
        ok
