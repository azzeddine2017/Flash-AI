# ===================================================================
# Context Intelligence — Importance-Weighted Context Selection
# ===================================================================
# Replaces the simple chronological sliding window in ContextEngine
# with a scoring system that prioritizes:
#   - User questions and errors (high)
#   - Recent messages (recency bonus)
#   - Tool results (medium — can be re-fetched)
#   - System notes (low)
# ===================================================================


class ContextIntelligence

    oContextEngine 

    # ===================================================================
    # Constructor
    # ===================================================================
    func init oEngine
        oContextEngine = oEngine

    # ===================================================================
    # Classify a message's importance (0.0 to 1.0)
    # ===================================================================
    func classifyMessage cRole, cContent, cType
        nWeight = 0.5  # Base weight

        # User messages with questions are high priority
        if cRole = "user"
            nWeight = 0.7
            if substr(cContent, "?") or substr(lower(cContent), "how") or 
               substr(lower(cContent), "why") or substr(lower(cContent), "fix")
                nWeight = 0.9
            ok
        ok

        # AI responses are medium-high priority (contain reasoning)
        if cRole = "assistant" and cType = "ai_response"
            nWeight = 0.6
        ok

        # Tool results are medium priority (can often be re-fetched)
        if cType = "tool_result"
            nWeight = 0.3
        ok

        # Tool call records are low priority (just metadata)
        if cType = "tool_call"
            nWeight = 0.2
        ok

        # System notes are low priority
        if cRole = "system" and cType = "system_note"
            nWeight = 0.1
        ok

        # Error messages are high priority (prevents repeating mistakes)
        cLower = lower(cContent)
        if substr(cLower, "error") or substr(cLower, "failed") or substr(cLower, "security error")
            if nWeight < 0.85
                nWeight = 0.85
            ok
        ok

        # Very long tool outputs get deprioritized (likely raw file dumps)
        if len(cContent) > 3000 and cType = "tool_result"
            nWeight = nWeight * 0.6
        ok

        return nWeight

    # ===================================================================
    # Build context with importance-weighted selection
    # Uses token budget instead of raw character count
    # ===================================================================
    func buildWeightedContext cRequestType, cCurrentCode, nTokenBudget
        if nTokenBudget <= 0  nTokenBudget = 4000  ok

        aAllMessages = oContextEngine.aConversationHistory
        if len(aAllMessages) = 0  return []  ok

        # Score all messages
        aScored = []
        for i = 1 to len(aAllMessages)
            oMsg = aAllMessages[i]
            cRole = getValueFromList(oMsg, "role", "user")
            cContent = getValueFromList(oMsg, "content", "")
            cType = getValueFromList(oMsg, "type", "chat")
            nWeight = classifyMessage(cRole, cContent, cType)

            # Recency bonus: more recent messages get a boost (0.0 to 0.3)
            nRecencyBonus = (i / len(aAllMessages)) * 0.3
            nFinalScore = nWeight + nRecencyBonus

            nTokenEst = estimateTokens(cContent)
            aScored + [i, nFinalScore, nTokenEst]
        next

        # Sort by score descending (highest priority first)
        for i = 1 to len(aScored)
            for j = 1 to len(aScored) - 1
                if aScored[j][2] < aScored[j+1][2]
                    temp = aScored[j]
                    aScored[j] = aScored[j+1]
                    aScored[j+1] = temp
                ok
            next
        next

        # Select messages within token budget
        nUsed = 0
        aSelectedIndices = []
        for oItem in aScored
            nIdx = oItem[1]
            nTokens = oItem[3]
            if nUsed + nTokens <= nTokenBudget
                aSelectedIndices + nIdx
                nUsed += nTokens
            ok
        next

        # Enforce Tool Call / Result Pairing (Fixing Orphaned Tools)
        aFixedIndices = []
        for nIdx in aSelectedIndices
            if find(aFixedIndices, nIdx) = 0 aFixedIndices + nIdx ok
            
            oMsg = aAllMessages[nIdx]
            cType = getValueFromList(oMsg, "type", "")
            
            if cType = "tool_call"
                aCalls = getValueFromList(oMsg, "tool_calls", [])
                if type(aCalls) = "LIST"
                    for oCall in aCalls
                        cTargetID = getValueFromList(oCall, "id", "")
                        if cTargetID != ""
                            for j = nIdx + 1 to len(aAllMessages)
                                oFutureMsg = aAllMessages[j]
                                if getValueFromList(oFutureMsg, "type", "") = "tool_result" and getValueFromList(oFutureMsg, "tool_call_id", "") = cTargetID
                                    if find(aFixedIndices, j) = 0 aFixedIndices + j ok
                                ok
                            next
                        ok
                    next
                ok
            elseif cType = "tool_result"
                cMyID = getValueFromList(oMsg, "tool_call_id", "")
                if cMyID != ""
                    for j = nIdx - 1 to 1 step -1
                        oPastMsg = aAllMessages[j]
                        if getValueFromList(oPastMsg, "type", "") = "tool_call"
                            aPastCalls = getValueFromList(oPastMsg, "tool_calls", [])
                            if type(aPastCalls) = "LIST"
                                for oCall in aPastCalls
                                    if getValueFromList(oCall, "id", "") = cMyID
                                        if find(aFixedIndices, j) = 0 aFixedIndices + j ok
                                        exit
                                    ok
                                next
                            ok
                        ok
                    next
                ok
            ok
        next
        aSelectedIndices = aFixedIndices

        # Sort selected indices to restore chronological order
        for i = 1 to len(aSelectedIndices)
            for j = 1 to len(aSelectedIndices) - 1
                if aSelectedIndices[j] > aSelectedIndices[j+1]
                    temp = aSelectedIndices[j]
                    aSelectedIndices[j] = aSelectedIndices[j+1]
                    aSelectedIndices[j+1] = temp
                ok
            next
        next

        # Build the context list in chronological order
        aContext = []
        for nIdx in aSelectedIndices
            oMsg = aAllMessages[nIdx]
            cRole = getValueFromList(oMsg, "role", "user")
            cContent = getValueFromList(oMsg, "content", "")
            oContextMsg = [["role", cRole], ["content", cContent]]

            # Preserve tool call metadata for OpenRouter/OpenAI compatibility
            cID = getValueFromList(oMsg, "tool_call_id", "")
            if cID != ""  
                oContextMsg + ["tool_call_id", cID]
                cName = getValueFromList(oMsg, "name", "")
                if cName != "" oContextMsg + ["name", cName] ok
            ok
            cCalls = getValueFromList(oMsg, "tool_calls", "")
            if cCalls != ""  oContextMsg + ["tool_calls", cCalls]  ok

            aContext + oContextMsg
        next

        return aContext

    # ===================================================================
    # Get context statistics for debugging/telemetry
    # ===================================================================
    func getStats
        aAll = oContextEngine.aConversationHistory
        nTotal = len(aAll)
        nTotalTokens = 0
        for oMsg in aAll
            cContent = getValueFromList(oMsg, "content", "")
            nTotalTokens += estimateTokens(cContent)
        next
        return [
            ["total_messages", nTotal],
            ["total_estimated_tokens", nTotalTokens],
            ["max_history", oContextEngine.nMaxHistoryLength]
        ]
