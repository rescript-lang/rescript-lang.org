# Design: Stage Docs Validation Around Explicit `example` Blocks First

## Goal

Restore the original contract for `scripts/test-examples.mjs`: only explicit ReScript `example` blocks are validated and used to sync `JS Output` fences.

This fixes the regression in PR `#1255`, where the new JS sync logic started treating plain ` ```res` blocks inside `CodeTab` as if they were runnable examples.

## Product Direction

The near-term goal is narrow and safe:

- explicit ` ```res example` blocks remain the unit of validation
- paired `JS Output` blocks are only checked for those example fences
- hidden ` ```res prelude` blocks remain available for invisible setup on a page

The longer-term direction is broader:

- validate all ReScript code blocks by default, even outside `CodeTab`
- allow docs authors to opt out explicitly for intentionally partial or narrative snippets
- add a shared support mechanism for invisible placeholder values when the docs should not show those definitions

That broader behavior is intentionally deferred to a follow-up change.

## Scope

### In scope for this fix

- tighten JS Output pairing so it begins only from ` ```res example`
- preserve the current compile check for `example`, `prelude`, and `sig`
- add regression coverage proving plain ` ```res` blocks in `CodeTab` are ignored by JS sync

### Out of scope for this fix

- validating every ` ```res` block in docs
- changing non-`CodeTab` fences to compile automatically
- introducing invisible globals or a shared support module
- adding markdown opt-out syntax

## Recommended Approach

Keep the implementation inside `scripts/test-examples.mjs` and narrow the selector that feeds the JS Output comparison pass.

This is the smallest change that restores expected behavior without discarding the useful work already done in the PR.

## Behavior

### Compile checks

The script should continue to compile the existing transformed temporary file built from:

- ` ```res example`
- ` ```res prelude`
- ` ```res sig`

This preserves current example-validation behavior.

### JS Output sync checks

Inside `<CodeTab labels={["ReScript", "JS Output"]}>`, the script should only compare compiler output for fences that are explicitly marked ` ```res example`.

The following should not trigger JS sync comparison in this phase:

- plain ` ```res`
- ` ```res prelude`
- ` ```res sig`
- ` ```rescript`
- highlighted forms such as ` ```res {4}`

## Parsing Strategy

The script already scans matching `CodeTab` regions line-by-line. The fix is to narrow the candidate ReScript fence detection for JS sync to ` ```res example` only.

Malformed `CodeTab` structures should still warn and skip comparison rather than guessing.

## Why This Phase First

There are many non-`example` ReScript fences in the docs, including narrative fragments that intentionally omit surrounding definitions such as `showMenu` or `displayGreeting`.

Widening validation immediately would create broad churn and couple this regression fix to a larger docs policy change.

By restoring `example` as the explicit opt-in unit first, we get:

- predictable behavior
- a small, reviewable patch
- room to design all-block validation deliberately instead of by accident

## Follow-Up Design Constraints

When the broader validation pass is designed, it should answer these questions explicitly:

1. Which ReScript fence kinds validate by default?
2. What is the opt-out marker for partial snippets?
3. How do hidden support values work?
4. Does invisible setup live per page, per section, or in a shared support module?
5. How do we avoid silently making docs depend on names the reader cannot see?

## Verification Plan

Add focused automated coverage for:

- stale output warnings on ` ```res example` blocks
- ignoring plain ` ```res` blocks inside matching `CodeTab`
- preserving malformed-tab warnings
- preserving the existing compile-failure behavior

The implementation should also be verified by running the example script tests directly after the change.
