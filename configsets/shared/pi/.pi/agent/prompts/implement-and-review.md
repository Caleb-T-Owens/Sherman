---
description: PI implement + review workflow — fixer implements, oracle reviews, fixer applies feedback
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "fixer" agent to implement: $@
   - Produce initial implementation with:
     - changed files
     - rationale
     - validation performed

2. Then, use the "oracle" agent to review the implementation from the previous step ({previous}).
   - Return a structured review:
     - **Go/No-Go** recommendation
     - **Pass criteria** (must be met before rework)
     - **Blocking issues** and **improvements**
     - **Risk assessment**

3. Finally, use the "fixer" agent to apply the oracle feedback from the previous step ({previous}).
   - Apply only blocking/required fixes first.
   - Reuse original acceptance criteria, and report:
     - what was fixed
     - remaining questions or unresolved items

For UI/UX-heavy work, use "designer" in steps 1 and 3 instead of "fixer".

Execute this as a chain and pass output between steps via {previous}.
