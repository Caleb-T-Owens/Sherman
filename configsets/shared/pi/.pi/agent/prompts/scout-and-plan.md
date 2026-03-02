---
description: PI planning workflow — explorer gathers scoped context, oracle returns a concrete plan
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "explorer" agent to gather scoped context for: $@
   - Define discovery scope (target files/modules, features, and stop conditions).
   - Return only actionable, high-signal context in this format:
     - **Scope**: what was searched and what was excluded
     - **Findings**: `path:line` references
     - **Assumptions** and **open questions**
   - Keep findings bounded (high confidence > noise).

2. Then, use the "oracle" agent to create a concrete implementation plan from the previous output ({previous}) for "$@".
   - Return:
     - **Plan** (ordered steps)
     - **Acceptance criteria**
     - **Risks + dependencies**
     - **Validation approach**

Execute this as a chain, passing output through {previous}. Do NOT implement.
