---
description: Pantheon planning workflow — explorer gathers context, oracle returns a concrete plan
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "explorer" agent to gather all relevant code context for: $@
2. Then, use the "oracle" agent to create a concrete implementation plan for "$@" using the previous output ({previous})

Execute this as a chain, passing output through {previous}. Do NOT implement.
