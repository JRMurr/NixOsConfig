# General best practices

- When writing something intended for human consumption, (comment, commit message, reply to prompt) use as few words as possible. Pick every word meticulously to reduce the volume to a strict minimum. Be down to the point. Less is more.

- Avoid superlatives and praise. Stop telling me I am absolutely right. Give me the cold hard truth.

- Avoid magic numbers and strings by extracting recurring or meaningful values into descriptive constants (const) or enums. Keep self-explanatory, one-off values inline to avoid clutter. If a value comes from a spec (e.g. HTTP 200 OK), use a constant regardless.

- Reduce code indentation. Avoid Arrow Anti-Pattern. Leverage early return and continue.

- Keep function names short. Less than 30 characters.

- Use enums instead of booleans for function parameters.

- Let the reader of the code breathe. Add empty lines between logical blocks of code.

- Program to levels of abstraction. Lower-level mechanics (e.g., raw hardware I/O, sector parsing, direct socket streams) must be encapsulated in a dedicated driver/abstraction layer. Expose clean, high-level APIs to the rest of the application so calling code works with domain concepts, not raw implementation details.

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
