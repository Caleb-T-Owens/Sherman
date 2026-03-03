# AGENT.md — Caleb Owens working preferences

_Last updated: 2026-03-01_

## Purpose

This file describes inferred collaboration and engineering preferences for Caleb Owens.
Use it as a default style guide for AI-assisted work.

Sources used:
- `https://cto.je` (plus local source in `projects/website4/src/pages/**`)
- public metadata from `https://github.com/Caleb-T-Owens`
- authored work in `projects/gitbutler-client`

If project/repo instructions conflict, follow the project/repo instructions.

---

## Quick defaults (apply unless told otherwise)

1. **Model first for non-trivial work**: align on problem, invariants, and trade-offs before coding.
2. **Prefer small, robust changes** over large rewrites.
3. **Be explicit** in names, state transitions, contracts, and outcomes.
4. **Prioritize correctness** (especially in Git/rebase/merge logic).
5. **Keep responses concise and structured**: changed files + validation status.

---

## Communication style

- Direct, practical, low-fluff.
- Friendly/human tone is good; avoid hype or marketing voice.
- Prefer clear reasoning over confident guessing.
- Use concrete examples and explicit conclusions when explaining decisions.
- Ask targeted clarification questions only when they unblock progress.

---

## Engineering principles

- **Model-driven**: requirements/invariants before implementation details.
- **Pragmatic**: maintainable and understandable beats clever.
- **Consistent**: align with existing lint/format/style and project conventions.
- **Iterative**: prefer versioned, incremental improvements.
- **Voice-preserving**: keep docs/UI wording consistent with existing project tone.

---

## Implementation protocol

### For non-trivial tasks (default)

Before implementation, align on:
1. Problem + desired outcome
2. Scope + non-goals
3. Domain terms/entities + invariants
4. Operation contract (inputs, outputs, no-op, errors)
5. Edge cases/failure modes + validation plan
6. Risks/trade-offs + recommended path

If the task is trivial, use a compact 1–3 bullet version.

### Collaboration boundaries

- Do not silently finalize behavior-impacting spec decisions.
- Surface options and recommend one when multiple paths are viable.
- If uncertainty could affect behavior, pause and ask.

---

## Coding preferences (inferred)

### Naming and API shape

- Use explicit, domain-revealing names.
- Prefer typed outcomes (`*Outcome`, `*Result`) over magic values/ambiguous tuples.
- Make state transitions and operation semantics obvious.

### Architecture

- Favor layered paths:
  1. external/API entrypoint
  2. implementation core
  3. side-effect adapters/boundaries
- In TS/Svelte, prefer service-style organization and typed state flow over scattered component logic.

### Error handling

- Fail fast on invariant violations.
- Include contextual, debuggable error messages.
- Return explicit no-op outcomes when “nothing to do” is valid.

### Comments/docs

- Document intent and invariants for complex flows.
- Explain **why**, not only **what**.
- Keep docs and user-facing text in sync with behavior changes.

### Testing

- Add/keep tests for edge cases and regression-prone logic.
- Prefer descriptive test names (scenario + expected behavior).
- For graph/merge/rebase behavior, structural snapshots are acceptable when they improve debuggability.

### Git-critical logic

- Treat merge/rebase/parentage/conflict behavior as correctness-critical.
- Avoid shortcuts in Git algorithms unless safety is demonstrated.
- Validate parent ordering, conflict handling, and metadata behavior explicitly.

---

## Response/output expectations

- Keep responses concise and structured.
- For non-trivial requests, present model/design first, then implementation.
- Always list changed files.
- State what validation was run (or why not run).
- Offer useful follow-ups when relevant (e.g., tests/docs tightening).

---

## Do / Don’t

### Do

- Be explicit, typed, and intention-revealing.
- Align on model/design first for non-trivial changes.
- Add context-rich errors and focused tests.
- Preserve project voice and conventions.

### Don’t

- Don’t introduce vague abstractions without clear payoff.
- Don’t hide invariants in implicit behavior.
- Don’t do broad rewrites when a focused change is sufficient.
- Don’t pad responses with unnecessary narrative.

---

## Evidence anchors (non-exhaustive)

Website content:
- `projects/website4/src/pages/index.mdx`
- `projects/website4/src/pages/projects.mdx`
- `projects/website4/src/pages/thoughts/reasonable-llm-usage.mdx`
- `projects/website4/src/pages/thoughts/the-anti-blog.mdx`
- `projects/website4/src/pages/tech/model-driven-development.mdx`
- `projects/website4/src/pages/tech/do-3wm-care-about-linebreaks.mdx`

GitButler authored-style examples:
- `projects/gitbutler-client/crates/but-workspace/src/commit/mod.rs`
- `projects/gitbutler-client/crates/but-api/src/commit.rs`
- `projects/gitbutler-client/crates/but-rebase/src/graph_rebase/rebase.rs`
- `projects/gitbutler-client/crates/but-rebase/src/graph_rebase/testing.rs`
- `projects/gitbutler-client/apps/desktop/src/lib/stacks/stackService.svelte.ts`
- `projects/gitbutler-client/apps/desktop/src/lib/codegen/messages.ts`
- `projects/gitbutler-client/apps/desktop/src/routes/[projectId]/+layout.svelte`

Public GitHub metadata:
- `https://api.github.com/users/Caleb-T-Owens`
- `https://api.github.com/users/Caleb-T-Owens/repos`
- `https://api.github.com/users/Caleb-T-Owens/events/public`
