# General best practices

- Be direct, you don't need to be overly supportive of me.

## SESSION.md

While working, if you come across any bugs, missing features, or other oddities about the implementation, structure, or workflow, add a concise description of them to SESSION.md to defer solving such incidental tasks until later. You do not need to fix them all straight away unless they block your progress; writing them down is often sufficient. Do not write your accomplishments into this file.

## Testing

Always think how changes can get under test. If no testing framework is setup, prompt the user on if you should make one.
When possible do property based testing. In rust prefer proptest.

**IMPORTANT** Whenever possible follow red green test driven development. Ie when making a feature or trying to fix a user reported issue, first make a test that is failing.
Then work on the implementation until it passes. Follow a similar idea for refactors.

## Debugging

**IMPORTANT** Always verify your assumptions. If you read code and form a hypothesis about a bug, don't just propose a fix based on that guess. Confirm it first by adding logging, running the code, or otherwise empirically validating what's actually happening. Reading code can mislead — runtime behavior is the source of truth.

Prefer fixes that address the root cause, even if it means a larger change. Avoid band-aid solutions that paper over symptoms without solving the underlying problem.

## Commits

Make commits as you go when its reasonable. Prompt the user if its on a main/release branch about whether to branch first.

## Code style preferences

- Use realistic names for types and variables in examples and documentation.
- Document when you have intentionally omitted code that the reader might otherwise expect to be present.
- Add TODO comments for features or nuances that were deemed not important to add, support, or implement right away.

### Literate Programming

Apply literate programming principles to make code self-documenting and maintainable:

1. **Explain the Why, Not Just the What**: Focus on business logic, design decisions, and reasoning rather than describing what the code obviously does.

2. **Top-Down Narrative Flow**: Structure code to read like a story with clear sections that build logically:
   ```rust
   // ==============================================================================
   // Plugin Configuration Extraction
   // ==============================================================================

   // First, we extract plugin metadata from Cargo.toml to determine
   // what files we need to build and where to put them.
   ```

3. **Inline Context**: Place explanatory comments immediately before relevant code blocks, explaining the purpose and any important considerations.

4. **Avoid Over-Abstraction**: Prefer clear, well-documented inline code over excessive function decomposition when logic is sequential and context-dependent. Functions should serve genuine reusability, not just file organization.

Don't over-document simple utility functions, trivial getters/setters, or obvious wrapper code.

## Common failure modes

When I ask a narrow or oddly specific question, consider whether I might be solving the wrong problem (the XY problem). Ask about the underlying goal before diving into the proposed solution.

## Coding guidelines

Behavioral guidelines to reduce common LLM coding mistakes.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
