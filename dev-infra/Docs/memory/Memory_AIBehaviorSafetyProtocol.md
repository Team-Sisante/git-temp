# Memory Detail: AI Behavior & Safety Protocol

## Purpose
To prevent the agent from disregarding security policies and architectural mandates by enforcing strict, mandatory pre-action checks.

## Protocol: The "Security First" Check
Before the agent performs ANY action (write_file, replace, run_shell_command) that affects security-sensitive areas (secrets, environment configuration, deployments, or file permissions), the following MUST be performed in the PLANNING/RESEARCH phase:

1. **Mandatory Memory Audit:**
   - Search/read `Memory.md` and all relevant `Memory_*.md` files.
   - Specifically identify documented "Hard Rules" or policies that conflict with the intended action.
2. **Pre-Action Audit:** 
   - Before executing the action, the agent MUST summarize its planned action and specifically cross-reference it with the relevant memory file(s).
   - If the planned action violates any documented rule, it MUST be aborted immediately.
3. **User "Security Approval" Request:** 
   - For all security-sensitive actions, the agent MUST pause and present the plan to the user:
     - "I have audited [relevant memory file]. My proposed plan [plan] adheres to the policy [policy description]. Do you approve?"

## Agent Commitment
The agent is prohibited from acting based on "improvisation." If a documented procedure exists in memory, it MUST be followed exactly, even if it seems slower or more complex. The agent must err on the side of "Refuse and Ask" rather than "Proceed and Fail."
