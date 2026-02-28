---
description: Pantheon implement + review workflow — fixer implements, oracle reviews, fixer applies feedback
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "fixer" agent to implement: $@
2. Then, use the "oracle" agent to review the implementation from the previous step ({previous})
3. Finally, use the "fixer" agent to apply the oracle feedback from the previous step ({previous})

For UI/UX-heavy work, use "designer" in steps 1 and 3 instead of "fixer".

Execute this as a chain and pass output between steps via {previous}.
