# ===================================================================
# Telemetry - Performance Monitoring & Metrics System
# ===================================================================
# Provides:
#   - Tool execution timing (latency per tool)
#   - API call tracking (latency, tokens, provider)
#   - Agentic loop iteration counting
#   - Session-level performance summary
#   - Persistent metrics export for analysis
# ===================================================================

class Telemetry

    # Session Timing
    nSessionStartClock = 0

    # Metrics Storage
    aToolMetrics  = []    # [tool_name, duration_ms, success, timestamp]
    aAPIMetrics   = []    # [provider, latency_ms, tokens, timestamp]
    aLoopMetrics  = []    # [request_id, iterations, total_ms, tools_used]

    # Counters
    nTotalToolCalls  = 0
    nTotalAPICalls   = 0
    nTotalErrors     = 0
    nTotalLoops      = 0

    # ===================================================================
    # Constructor
    # ===================================================================
    func init
        nSessionStartClock = clock()

    # ===================================================================
    # Tool Execution Metrics
    # ===================================================================
    # Start Tool Timer
    # ===================================================================
    func startToolTimer
        return clock()
        
    # ===================================================================
    # Record Tool Execution
    # ===================================================================
    func recordToolExecution cToolName, nStartClock, bSuccess
        nDuration = ((clock() - nStartClock) * 1000) / clockspersecond()
        nTotalToolCalls++
        if not bSuccess
            nTotalErrors++
        ok
        aToolMetrics + [
            ["tool", cToolName],
            ["duration_ms", nDuration],
            ["success", bSuccess],
            ["timestamp", date() + " " + time()]
        ]
        # Keep only last 200 entries to prevent memory bloat
        if len(aToolMetrics) > 200
            del(aToolMetrics, 1)
        ok

    # ===================================================================
    # API Call Metrics
    # ===================================================================
    func startAPITimer
        return clock()

    func recordAPICall cProvider, nStartClock, nTokens
        nLatency = ((clock() - nStartClock) * 1000) / clockspersecond()
        nTotalAPICalls++
        aAPIMetrics + [
            ["provider", cProvider],
            ["latency_ms", nLatency],
            ["tokens", nTokens],
            ["timestamp", date() + " " + time()]
        ]
        if len(aAPIMetrics) > 200
            del(aAPIMetrics, 1)
        ok

    # ===================================================================
    # Agentic Loop Metrics
    # ===================================================================
    func recordLoop cRequestId, nIterations, nStartClock, nToolsUsed
        nTotalMs = ((clock() - nStartClock) * 1000) / clockspersecond()
        nTotalLoops++
        aLoopMetrics + [
            ["request_id", cRequestId],
            ["iterations", nIterations],
            ["total_ms", nTotalMs],
            ["tools_used", nToolsUsed],
            ["timestamp", date() + " " + time()]
        ]
        if len(aLoopMetrics) > 100
            del(aLoopMetrics, 1)
        ok

    # ===================================================================
    # Session Duration
    # ===================================================================
    func getSessionDurationSec
        return (clock() - nSessionStartClock) / clockspersecond()

    # ===================================================================
    # Generate Performance Report
    # ===================================================================
    func getReport
        nDuration = getSessionDurationSec()

        cReport = "╔══════════════════════════════════════════════╗" + nl
        cReport += "║        FLASH AI — Performance Report        ║" + nl
        cReport += "╠══════════════════════════════════════════════╣" + nl
        cReport += "║ Session Duration : " + formatDuration(nDuration) + nl
        cReport += "║ Total API Calls  : " + nTotalAPICalls + nl
        cReport += "║ Total Tool Calls : " + nTotalToolCalls + nl
        cReport += "║ Total Errors     : " + nTotalErrors + nl
        cReport += "║ Agentic Loops    : " + nTotalLoops + nl
        cReport += "╠══════════════════════════════════════════════╣" + nl

        # Tool Performance Breakdown
        if nTotalToolCalls > 0
            cReport += "║ Tool Execution Summary:" + nl

            # Aggregate by tool name
            aToolSummary = aggregateToolMetrics()
            for oTool in aToolSummary
                cName = getValueFromList(oTool, "tool", "")
                nCount = getValueFromList(oTool, "count", 0)
                nAvg = getValueFromList(oTool, "avg_ms", 0)
                nSucc = getValueFromList(oTool, "success_count", 0)
                cRate = "" + floor((nSucc / max(nCount, 1)) * 100) + "%"
                cReport += "║   " + left(cName + copy(" ", 22), 22)
                cReport += " x" + left("" + nCount + copy(" ", 4), 4)
                cReport += " avg:" + left("" + floor(nAvg) + "ms" + copy(" ", 8), 8)
                cReport += " ok:" + cRate + nl
            next
        ok

        # API Latency Summary
        if nTotalAPICalls > 0
            cReport += "╠══════════════════════════════════════════════╣" + nl
            cReport += "║ API Latency Summary:" + nl
            aAPISummary = aggregateAPIMetrics()
            for oAPI in aAPISummary
                cProv = getValueFromList(oAPI, "provider", "")
                nAvgLat = getValueFromList(oAPI, "avg_latency_ms", 0)
                nTotalTok = getValueFromList(oAPI, "total_tokens", 0)
                nCalls = getValueFromList(oAPI, "count", 0)
                cReport += "║   " + left(cProv + copy(" ", 15), 15)
                cReport += " calls:" + left("" + nCalls + copy(" ", 4), 4)
                cReport += " avg:" + left("" + floor(nAvgLat) + "ms" + copy(" ", 8), 8)
                cReport += " tokens:" + nTotalTok + nl
            next
        ok

        # Loop Stats
        if nTotalLoops > 0
            cReport += "╠══════════════════════════════════════════════╣" + nl
            cReport += "║ Agentic Loop Summary:" + nl
            nAvgIter = 0
            nAvgTime = 0
            for oLoop in aLoopMetrics
                nAvgIter += getValueFromList(oLoop, "iterations", 0)
                nAvgTime += getValueFromList(oLoop, "total_ms", 0)
            next
            nAvgIter = floor(nAvgIter / max(len(aLoopMetrics), 1))
            nAvgTime = floor(nAvgTime / max(len(aLoopMetrics), 1))
            cReport += "║   Avg iterations/request : " + nAvgIter + nl
            cReport += "║   Avg time/request       : " + nAvgTime + "ms" + nl
        ok

        cReport += "╚══════════════════════════════════════════════╝" + nl
        return cReport

    # ===================================================================
    # Export Metrics to JSON
    # ===================================================================
    func exportToJSON
        oExport = [
            ["session_duration_sec", getSessionDurationSec()],
            ["total_api_calls", nTotalAPICalls],
            ["total_tool_calls", nTotalToolCalls],
            ["total_errors", nTotalErrors],
            ["total_loops", nTotalLoops],
            ["tool_metrics", aToolMetrics],
            ["api_metrics", aAPIMetrics],
            ["loop_metrics", aLoopMetrics]
        ]
        return jsonEncodeValue(oExport)

    # ===================================================================
    # Reset All Metrics
    # ===================================================================
    func reset
        aToolMetrics  = []
        aAPIMetrics   = []
        aLoopMetrics  = []
        nTotalToolCalls = 0
        nTotalAPICalls  = 0
        nTotalErrors    = 0
        nTotalLoops     = 0
        nSessionStartClock = clock()

    # ===================================================================
    # Private Aggregation Helpers
    # ===================================================================
    private

    func aggregateToolMetrics
        aNames = []
        aResult = []
        for oMetric in aToolMetrics
            cName = getValueFromList(oMetric, "tool", "")
            if find(aNames, cName) = 0
                aNames + cName
                aResult + [
                    ["tool", cName],
                    ["count", 0],
                    ["total_ms", 0],
                    ["avg_ms", 0],
                    ["success_count", 0]
                ]
            ok
        next
        for oMetric in aToolMetrics
            cName = getValueFromList(oMetric, "tool", "")
            nDur = getValueFromList(oMetric, "duration_ms", 0)
            bSucc = getValueFromList(oMetric, "success", false)
            for i = 1 to len(aResult)
                if getValueFromList(aResult[i], "tool", "") = cName
                    nOldCount = getValueFromList(aResult[i], "count", 0)
                    nOldTotal = getValueFromList(aResult[i], "total_ms", 0)
                    nOldSucc = getValueFromList(aResult[i], "success_count", 0)
                    aResult[i] = [
                        ["tool", cName],
                        ["count", nOldCount + 1],
                        ["total_ms", nOldTotal + nDur],
                        ["avg_ms", (nOldTotal + nDur) / (nOldCount + 1)],
                        ["success_count", nOldSucc + (bSucc = true)]
                    ]
                    exit
                ok
            next
        next
        return aResult

    func aggregateAPIMetrics
        aProviders = []
        aResult = []
        for oMetric in aAPIMetrics
            cProv = getValueFromList(oMetric, "provider", "")
            if find(aProviders, cProv) = 0
                aProviders + cProv
                aResult + [
                    ["provider", cProv],
                    ["count", 0],
                    ["total_latency_ms", 0],
                    ["avg_latency_ms", 0],
                    ["total_tokens", 0]
                ]
            ok
        next
        for oMetric in aAPIMetrics
            cProv = getValueFromList(oMetric, "provider", "")
            nLat = getValueFromList(oMetric, "latency_ms", 0)
            nTok = getValueFromList(oMetric, "tokens", 0)
            for i = 1 to len(aResult)
                if getValueFromList(aResult[i], "provider", "") = cProv
                    nOldCount = getValueFromList(aResult[i], "count", 0)
                    nOldLat = getValueFromList(aResult[i], "total_latency_ms", 0)
                    nOldTok = getValueFromList(aResult[i], "total_tokens", 0)
                    aResult[i] = [
                        ["provider", cProv],
                        ["count", nOldCount + 1],
                        ["total_latency_ms", nOldLat + nLat],
                        ["avg_latency_ms", (nOldLat + nLat) / (nOldCount + 1)],
                        ["total_tokens", nOldTok + nTok]
                    ]
                    exit
                ok
            next
        next
        return aResult

    func formatDuration nSec
        if nSec < 60
            return "" + floor(nSec) + "s"
        ok
        nMin = floor(nSec / 60)
        nRemSec = floor(nSec % 60)
        return "" + nMin + "m " + nRemSec + "s"

    func max a, b
        if a > b return a ok
        return b

    func floor n
        return (n - (n % 1))
