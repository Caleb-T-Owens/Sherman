# CLAUDE.md - Guidance for AI Assistants

Welcome! This file is for AI assistants (like Claude Code) working on projects in the Sherman monorepo.

## Start by Reading the README

Before making changes to any project, **read the project's `README.md` thoroughly**. It contains:
- Design philosophy and core principles
- Architecture and structure
- Key patterns and conventions
- Development guidelines

The README is the source of truth for how the project should evolve.

## Keep READMEs Up to Date

Project READMEs should be high-level and conceptual to remain maintainable. When making changes:

### When to Update the README

1. **New features**: Add to Contributing section if they introduce new patterns
2. **Changed patterns**: Update the relevant documentation section
3. **New major components**: Update Architecture or Structure sections
4. **Major architectural changes**: Update Design Philosophy section

### How to Update the README

- Document **why** and **what**, not line-by-line code specifics
- Use diagrams (Mermaid) for relationships and flows instead of code examples
- Link to actual source files rather than duplicating code
- Keep high-level, avoid implementation details that will become outdated

### What Not to Include

- ❌ Code examples that mirror actual files
- ❌ Implementation-specific details (line numbers, specific method signatures)
- ❌ Step-by-step code walkthroughs
- ❌ Detailed examples that won't age well

### What to Include

- ✅ Design philosophy and principles
- ✅ Architecture diagrams (Mermaid ER, flowcharts, etc.)
- ✅ Pattern explanations and when to use them
- ✅ High-level feature descriptions
- ✅ Development setup and deployment instructions
- ✅ References to source files for specific details

## General Principles

When working on Sherman projects, keep these principles in mind:

- **Documentation First**: Keep README.md and other docs current
- **Semantic Clarity**: Use clear structure and naming
- **Server-Side by Default**: Prefer backend logic over client-side hacks
- **No Dead Code**: Don't create placeholders or unused code
- **Reference Actual Files**: Point developers to source files, don't duplicate content

## Before Making Changes

Ask yourself:
1. Have I read the project's README.md?
2. Do I understand the design philosophy and principles?
3. Will my changes require README updates?
4. Am I introducing new patterns that should be documented?
5. Could I reference an actual file instead of adding code to the README?

## Questions?

If you're unsure whether something should be documented or how to document it, err on the side of:
- Keeping the README at a higher level
- Using diagrams instead of code
- Pointing to source files
- Removing outdated documentation rather than updating it with new specifics

Thanks for helping keep these projects clean, well-documented, and maintainable!
