# ===================================================================
# LongTermMemory - Persistent Cross-Session Knowledge Base
# ===================================================================
# Provides:
#   - Persistent fact storage across sessions (JSON-backed)
#   - Keyword-based recall (semantic-lite retrieval)
#   - Automatic learning from tool results and conversations
#   - Memory importance scoring and pruning
#   - Categories: project_fact, user_preference, error_pattern,
#                 code_pattern, file_knowledge
# ===================================================================

class LongTermMemory

    # Storage
    aMemories = []
    cMemoryFile = ""

    # Configuration
    nMaxMemories = 300
    bDirty = false      # Track unsaved changes

    # ===================================================================
    # Constructor
    # ===================================================================
    func init
        cMemoryFile = APP_PATH("ai/memory/knowledge_base.json")
        ensureDirectoryExists(APP_PATH("ai/memory"))
        loadMemories()

    # ===================================================================
    # Remember - Store a new fact
    # ===================================================================
    # Categories: project_fact, user_preference, error_pattern,
    #             code_pattern, file_knowledge, tool_learning
    func remember cCategory, cFact, nImportance
        if type(cFact) != "STRING" or trim(cFact) = "" return ok
        cFact = trim(cFact)
        cFact = substr(cFact, char(13), "")
        cFact = substr(cFact, char(10), " ")
        if type(nImportance) != "NUMBER" nImportance = 5 ok
        if nImportance < 1  nImportance = 1 ok
        if nImportance > 10 nImportance = 10 ok

        # Check for duplicates (exact or very similar)
        cFactLower = lower(cFact)
        for oMem in aMemories
            cExisting = lower(trim(getValueFromList(oMem, "fact", "")))
            if cExisting = cFactLower
                # Update access count instead of duplicating
                updateAccessCount(oMem)
                return
            ok
        next

        oMemory = [
            ["category", cCategory],
            ["fact", cFact],
            ["importance", nImportance],
            ["created", date() + " " + time()],
            ["access_count", 0],
            ["last_accessed", ""]
        ]

        aMemories + oMemory
        bDirty = true
        save()

        # Prune if over limit
        if len(aMemories) > nMaxMemories
            pruneMemories()
        ok

    # ===================================================================
    # Recall - Retrieve relevant memories by query
    # ===================================================================
    func recall cQuery, nMaxResults
        if type(nMaxResults) != "NUMBER" or nMaxResults <= 0
            nMaxResults = 5
        ok

        aResults = []
        cQueryLower = lower(trim(cQuery))

        if cQueryLower = "" return aResults ok

        # Split query into keywords (words > 2 chars)
        # Handle punctuation to avoid "code," or "file."
        aQueryWords = []
        cCleanQuery = ""
        for i = 1 to len(cQueryLower)
            cChar = cQueryLower[i]
            nAsc = ascii(cChar)
            # Filter out ASCII punctuation marks, preserving English, Arabic, and UTF-8 characters
            if (nAsc >= 33 and nAsc <= 47) or (nAsc >= 58 and nAsc <= 64) or (nAsc >= 91 and nAsc <= 96) or (nAsc >= 123 and nAsc <= 126)
                cCleanQuery += " "
            else
                cCleanQuery += cChar
            ok
        next

        aRaw = split(cCleanQuery, " ")
        for cWord in aRaw
            cWord = trim(cWord)
            if len(cWord) > 2
                aQueryWords + cWord
            ok
        next

        if len(aQueryWords) = 0 return aResults ok

        # Score each memory against query keywords
        aScored = []
        for i = 1 to len(aMemories)
            oMem = aMemories[i]
            cFact = lower(getValueFromList(oMem, "fact", ""))
            cCat = lower(getValueFromList(oMem, "category", ""))
            nImportance = 0 + getValueFromList(oMem, "importance", 5)

            nScore = 0
            for cWord in aQueryWords
                if substr(cFact, cWord)
                    nScore += 2
                ok
                if substr(cCat, cWord)
                    nScore += 1
                ok
            next

            # Boost by importance (normalized 0-1)
            nScore = nScore + (nImportance / 10)

            if nScore > 0
                aScored + [i, nScore]
            ok
        next

        # Sort by score descending (bubble sort — small dataset)
        for i = 1 to len(aScored)
            for j = 1 to len(aScored) - 1
                if aScored[j][2] < aScored[j+1][2]
                    temp = aScored[j]
                    aScored[j] = aScored[j+1]
                    aScored[j+1] = temp
                ok
            next
        next

        # Return top N
        nCount = min(nMaxResults, len(aScored))
        for i = 1 to nCount
            nIdx = aScored[i][1]
            aResults + aMemories[nIdx]
            updateAccessCount(aMemories[nIdx])
        next

        return aResults

    # ===================================================================
    # Recall by Category
    # ===================================================================
    func recallByCategory cCategory, nMaxResults
        if type(nMaxResults) != "NUMBER" or nMaxResults <= 0
            nMaxResults = 10
        ok
        aResults = []
        cCatLower = lower(trim(cCategory))
        for oMem in aMemories
            if lower(getValueFromList(oMem, "category", "")) = cCatLower
                aResults + oMem
                if len(aResults) >= nMaxResults exit ok
            ok
        next
        return aResults

    # ===================================================================
    # Build Context Injection (for AI prompts)
    # ===================================================================
    func buildContextInjection cQuery, nMaxTokens
        aRelevant = recall(cQuery, 5)

        # Always supplement with top user preferences and project facts
        aPrefs = recallByCategory("user_preference", 3)
        for oP in aPrefs
            if find(aRelevant, oP) = 0 aRelevant + oP ok
        next

        aFacts = recallByCategory("project_fact", 3)
        for oF in aFacts
            if find(aRelevant, oF) = 0 aRelevant + oF ok
        next

        if len(aRelevant) = 0 return "" ok

        cInjection = "[LONG-TERM MEMORY - Persistent Knowledge Base]" + nl
        nUsed = len(cInjection)
        nCount = 0

        for oMem in aRelevant
            cFact = getValueFromList(oMem, "fact", "")
            cCat = getValueFromList(oMem, "category", "")
            cFact = substr(cFact, char(13), "")
            cFact = substr(cFact, char(10), " ")
            cLine = "• [" + cCat + "] " + cFact + nl
            nEstTokens = estimateTokens(cLine)
            if nUsed + nEstTokens > nMaxTokens
                exit
            ok
            cInjection += cLine
            nUsed += nEstTokens
            nCount++
        next

        if nCount = 0 return "" ok
        cInjection += "[END MEMORY - " + nCount + " facts active]" + nl
        return cInjection

    # ===================================================================
    # Auto-Learn from Tool Results
    # ===================================================================
    func learnFromToolResult cToolName, aParams, bSuccess, cResultMsg
        # Learn file structure from list_files
        if cToolName = "list_files" and bSuccess
            cDir = ""
            if len(aParams) > 0 
                # Smart Parameter Unwrapping (Handle both [key,val] pairs and flat values)
                if type(aParams[1]) = "LIST" and len(aParams[1]) >= 2
                    cDir = "" + aParams[1][2] # Extract Value from [Key, Value]
                else
                    cDir = "" + aParams[1]
                ok
            ok
            if cDir != ""
                remember("file_knowledge", "Directory '" + cDir + "' was explored. Contents: " + left(cResultMsg, 200), 3)
            ok
        ok

        # Learn from errors (higher importance)
        if not bSuccess and len(cResultMsg) > 10
            remember("error_pattern", "Tool '" + cToolName + "' failed: " + left(cResultMsg, 150), 7)
        ok

        # Learn from project analysis
        if cToolName = "analyze_project" and bSuccess
            remember("project_fact", left(cResultMsg, 250), 6)
        ok

    # ===================================================================
    # Learn from User Dialogue
    # ===================================================================
    func learnFromDialogue cRole, cContent
        if cRole != "user" return ok
        cLower = lower(cContent)
        
        # User preferences / instructions (English & Arabic)
        if substr(cLower, "i prefer") or substr(cLower, "use ") or substr(cLower, "always") or substr(cLower, "don't") or
           substr(cLower, "أفضل") or substr(cLower, "استخدم") or substr(cLower, "دائما") or substr(cLower, "لا تفعل") or
           substr(cLower, "اسمي") or substr(cLower, "أنا") or substr(cLower, "اريد") or substr(cLower, "أريد")
            remember("user_preference", cContent, 6)
        ok
        
        # Project facts (English & Arabic)
        if substr(cLower, "project is") or substr(cLower, "this site") or substr(cLower, "the database") or
           substr(cLower, "المشروع") or substr(cLower, "الموقع") or substr(cLower, "قاعدة البيانات") or substr(cLower, "الكود")
            remember("project_fact", cContent, 5)
        ok
        
        # Secrets / Keys (Warning - don't store real keys, but store awareness)
        if substr(cLower, "api_key") or substr(cLower, "password")
            remember("security_note", "User mentioned sensitive credentials at " + date(), 8)
        ok


    # ===================================================================
    # Get All Memories (for inspection)
    # ===================================================================
    func getAllMemories
        return aMemories

    func getMemoryCount
        return len(aMemories)

    # ===================================================================
    # Persistence - Save / Load with Markdown Sync
    # ===================================================================
    func save
        if not bDirty and len(aMemories) > 0 return ok
        try
            cJSON = jsonEncodeValue(aMemories)
            write(cMemoryFile, cJSON)
            syncMarkdownFile()
            bDirty = false
        catch
            # Silent fail on save
        done

    func loadMemories
        if fexists(cMemoryFile)
            try
                cJSON = read(cMemoryFile)
                if len(cJSON) > 2
                    aTemp = json2list(cJSON)
                    if type(aTemp) = "LIST"
                        aMemories = aTemp
                    ok
                ok
            catch
                aMemories = []
            done
        ok

    # ===================================================================
    # Forget / Delete Memory
    # ===================================================================
    func forget cKeyword
        if type(cKeyword) != "STRING" or trim(cKeyword) = "" return 0 ok
        cKeyLower = lower(trim(cKeyword))
        nRemoved = 0
        aKept = []
        for oMem in aMemories
            cFact = lower(getValueFromList(oMem, "fact", ""))
            cCat = lower(getValueFromList(oMem, "category", ""))
            if substr(cFact, cKeyLower) > 0 or substr(cCat, cKeyLower) > 0
                nRemoved++
            else
                aKept + oMem
            ok
        next
        if nRemoved > 0
            aMemories = aKept
            bDirty = true
            save()
        ok
        return nRemoved

    # ===================================================================
    # Export and Sync Memory as Markdown (Structured Document)
    # Uses ysdragon/markdown for parsing and HTML generation
    # ===================================================================
    func exportMarkdown
        cMD = "# 🧠 FLASH AI - Long-Term Knowledge Base" + nl + nl
        cMD += "> *Last Synchronized:* " + date() + " " + time() + " | *Total Memories:* " + len(aMemories) + nl + nl

        aCategories = ["user_preference", "project_fact", "code_pattern", "error_pattern", "file_knowledge", "general"]
        aCatTitles  = [
            "👤 User Preferences & Directives",
            "🏛️ Project Architecture & Facts",
            "💻 Code Patterns & Conventions",
            "🛡️ Error Patterns & Self-Corrections",
            "📂 Explored Files & Structure",
            "💡 General Knowledge"
        ]

        for cIdx = 1 to len(aCategories)
            cCat = aCategories[cIdx]
            cTitle = aCatTitles[cIdx]
            
            aCatItems = []
            for oMem in aMemories
                if getValueFromList(oMem, "category", "") = cCat
                    aCatItems + oMem
                ok
            next

            if len(aCatItems) > 0
                cMD += "## " + cTitle + nl + nl
                for oItem in aCatItems
                    cFact = getValueFromList(oItem, "fact", "")
                    nImp = getValueFromList(oItem, "importance", 5)
                    cDate = getValueFromList(oItem, "created", "")
                    cMD += "- **[" + nImp + "/10]** " + cFact + " *(recorded: " + cDate + ")*" + nl
                next
                cMD += nl
            ok
        next
        return cMD

    func syncMarkdownFile
        try
            cMDPath = APP_PATH("ai/memory/MEMORY.md")
            cContent = exportMarkdown()
            write(cMDPath, cContent)
        catch
        done

    func renderToHTML cMarkdownText
        if isclass("Markdown")
            try
                oMD = new Markdown
                return oMD.toHTML(cMarkdownText)
            catch
            done
        ok
        return markdownToHTML(cMarkdownText)


    # ===================================================================
    # Private Helpers
    # ===================================================================
    private

    func updateAccessCount oMem
        for i = 1 to len(oMem)
            if type(oMem[i]) = "LIST" and len(oMem[i]) >= 2
                if oMem[i][1] = "access_count"
                    oMem[i][2] = oMem[i][2] + 1
                ok
                if oMem[i][1] = "last_accessed"
                    oMem[i][2] = date() + " " + time()
                ok
            ok
        next

    func pruneMemories
        # Remove lowest-scoring memories to stay under limit
        # Score = importance + (access_count * 0.5) - age_penalty
        if len(aMemories) <= nMaxMemories return ok

        # Calculate scores
        aScores = []
        for i = 1 to len(aMemories)
            nImp = getValueFromList(aMemories[i], "importance", 5)
            nAccess = getValueFromList(aMemories[i], "access_count", 0)
            nScore = nImp + (nAccess * 0.5)
            aScores + [i, nScore]
        next

        # Sort ascending (weakest first)
        for i = 1 to len(aScores)
            for j = 1 to len(aScores) - 1
                if aScores[j][2] > aScores[j+1][2]
                    temp = aScores[j]
                    aScores[j] = aScores[j+1]
                    aScores[j+1] = temp
                ok
            next
        next

        # Remove weakest entries until under limit
        nRemove = len(aMemories) - nMaxMemories
        aToRemove = []
        for i = 1 to nRemove
            aToRemove + aScores[i][1]
        next

        # Remove in reverse index order to preserve indices
        for i = 1 to len(aToRemove)
            for j = 1 to len(aToRemove) - 1
                if aToRemove[j] < aToRemove[j+1]
                    temp = aToRemove[j]
                    aToRemove[j] = aToRemove[j+1]
                    aToRemove[j+1] = temp
                ok
            next
        next
        for nIdx in aToRemove
            if nIdx <= len(aMemories)
                del(aMemories, nIdx)
            ok
        next
        bDirty = true

    func min a, b
        if a < b return a ok
        return b
