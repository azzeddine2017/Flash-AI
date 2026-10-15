# ===================================================================
# Agent States Constants
# ===================================================================
AGENT_IDLE         = 0
AGENT_PLANNING     = 1
AGENT_CALLING_LLM  = 2
AGENT_EXEC_TOOL    = 3
AGENT_REFLECTING   = 4
AGENT_FINALIZING   = 5
AGENT_ERROR        = 6
AGENT_AWAITING_APPROVAL = 7

# ===================================================================
# Agent State Machine 
# Formal FSM replacing the simple while loop for the smart agent
# ===================================================================
class AgentStateMachine

    nCurrentState = AGENT_IDLE
    nMaxTransitions = 100
    aStateLog = []
    
    func init
        nCurrentState = AGENT_IDLE
        aStateLog = []

    func transition nNewState
        # Self-transition (maintaining current state) is allowed
        if nNewState = nCurrentState
            return true
        ok

        # Enforce formal deterministic transitions
        if not canTransition(nNewState)
            aStateLog + [
                ["from", nCurrentState],
                ["to", nNewState],
                ["status", "rejected"],
                ["timestamp", clock()]
            ]
            return false
        ok

        aStateLog + [
            ["from", nCurrentState],
            ["to", nNewState],
            ["status", "accepted"],
            ["timestamp", clock()]
        ]
        nCurrentState = nNewState
        return true
    
    func canTransition nTo
        # Define valid state transitions
        switch nCurrentState
            on AGENT_IDLE
                return nTo = AGENT_PLANNING or nTo = AGENT_CALLING_LLM or nTo = AGENT_ERROR
            on AGENT_PLANNING
                return nTo = AGENT_CALLING_LLM or nTo = AGENT_AWAITING_APPROVAL or nTo = AGENT_ERROR or nTo = AGENT_FINALIZING
            on AGENT_CALLING_LLM
                return nTo = AGENT_EXEC_TOOL or nTo = AGENT_FINALIZING or nTo = AGENT_ERROR or nTo = AGENT_AWAITING_APPROVAL or nTo = AGENT_PLANNING
            on AGENT_EXEC_TOOL
                return nTo = AGENT_REFLECTING or nTo = AGENT_CALLING_LLM or nTo = AGENT_ERROR or nTo = AGENT_AWAITING_APPROVAL or nTo = AGENT_FINALIZING
            on AGENT_REFLECTING
                return nTo = AGENT_CALLING_LLM or nTo = AGENT_FINALIZING or nTo = AGENT_AWAITING_APPROVAL or nTo = AGENT_ERROR
            on AGENT_ERROR
                return nTo = AGENT_REFLECTING or nTo = AGENT_FINALIZING or nTo = AGENT_IDLE
            on AGENT_FINALIZING
                return nTo = AGENT_IDLE or nTo = AGENT_ERROR
            on AGENT_AWAITING_APPROVAL
                return nTo = AGENT_PLANNING or nTo = AGENT_EXEC_TOOL or nTo = AGENT_CALLING_LLM or nTo = AGENT_FINALIZING or nTo = AGENT_IDLE or nTo = AGENT_ERROR
        off
        return false
    
    func getStateLog
        return aStateLog
