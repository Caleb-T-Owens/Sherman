---
description: PI implementation workflow — explorer maps context, oracle designs, fixer implements
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "explorer" agent to do bounded context discovery for: $@
   - Produce a scope map (modules/directories, files to inspect, and explicit stop conditions).
   - Return findings as:
     - **Scope**: what is in/out of scope
     - **Findings**: `path:line` items, prioritized by relevance
     - **Assumptions + risks**
     - **Open questions** (if any)

2. Then, use the "oracle" agent to produce an implementation plan from the prior output ({previous}) for "$@".
   - Return a compact plan with:
     - **Goal and acceptance criteria**
     - **Files to change** (ordered)
     - **Invariants / edge cases**
     - **Risks + mitigation**
     - **Verification checklist**
   - If information is insufficient, explicitly request clarification before continuing.

3. Finally, use the "fixer" agent to implement the plan from the previous step ({previous}).
   - Include:
     - `summary` of changes
     - file-by-file edits
     - verification commands/results
     - remaining risks

For UI/UX-heavy work, use "designer" instead of "fixer" in step 3.

Execute this as a chain and pass output between steps via {previous}.
