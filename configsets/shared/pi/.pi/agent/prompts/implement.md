---
description: Pantheon implementation workflow — explorer maps context, oracle plans, fixer implements
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "explorer" agent to find all code relevant to: $@
2. Then, use the "oracle" agent to produce an implementation plan for "$@" using the prior output ({previous})
3. Finally, use the "fixer" agent to implement the plan from the previous step ({previous})

For UI/UX-heavy work, use "designer" instead of "fixer" in step 3.

Execute this as a chain and pass output between steps via {previous}.
