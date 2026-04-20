# Design: Add `--update` Mode to `scripts/test-examples.mjs`

## Goal

Implement a real `--update` mode for `scripts/test-examples.mjs` so it can rewrite `JS Output` blocks from compiled ` ```res example` snippets instead of only warning that output is stale.

This extends the current example-only validation contract without widening which ReScript fences are considered runnable examples.

## Scope

### In scope

- add a real `--update` CLI mode to `scripts/test-examples.mjs`
- rewrite stale existing ` ```js` fences inside matching `CodeTab` blocks
- fill existing empty ` ```js` fences inside matching `CodeTab` blocks
- insert a missing ` ```js` fence before `</CodeTab>` when a matching tab contains a ` ```res example` block but no paired JS fence
- update `<CodeTab labels={["ReScript"]}>` to `<CodeTab labels={["ReScript", "JS Output"]}>` when `--update` adds or maintains a JS Output block
- leave multi-label `CodeTab` titles alone when they already have more than one label
- update relevant user-facing documentation so the new `--update` behavior is discoverable

### Out of scope

- validating plain ` ```res` fences
- rewriting non-`CodeTab` markdown fences
- renaming custom multi-label tabs such as `["ReScript", "JS Output (Module)"]`
- broad AST-based markdown rewriting
- adding invisible shared globals or broader all-block validation

## Recommended Approach

Keep the implementation inside `scripts/test-examples.mjs` and extend the existing line-oriented scanner with enough location data to rewrite the matching `CodeTab` region in-place.

This stays aligned with the current script structure, avoids introducing an MDX parser for a narrow maintenance workflow, and keeps the rewrite scope strictly limited to the `CodeTab` blocks the script already understands.

## Behavior

### Default mode

Running:

```sh
node scripts/test-examples.mjs
```

should continue to:

- compile example content and fail on compile errors
- warn about stale JS Output blocks
- warn about malformed `CodeTab` structures
- leave markdown files unchanged

### Update mode

Running:

```sh
node scripts/test-examples.mjs --update
```

should:

- compile the same example content as default mode
- rewrite stale ` ```js` fence contents to the current compiler output
- fill empty ` ```js` fences with the current compiler output
- create a missing ` ```js` fence before `</CodeTab>` when a matching `CodeTab` has a ` ```res example` block but no paired JS fence
- write the file back only when the content actually changes

Compile errors remain hard failures in update mode.

## `CodeTab` Label Rules

When `--update` writes a JS Output block into a `CodeTab`:

- if the labels are exactly `["ReScript"]`, rewrite them to `["ReScript", "JS Output"]`
- if the labels already contain more than one item, keep the labels unchanged

This preserves existing custom naming while still fixing the common single-label case automatically.

## Matching Rules

Eligible rewrite targets remain limited to `CodeTab` blocks that contain:

- a ` ```res example` fence
- and either:
  - an existing ` ```js` or ` ```javascript` fence
  - or no JS fence, in which case update mode may insert one

The following should still be ignored as JS sync sources:

- plain ` ```res`
- ` ```res prelude`
- ` ```res sig`
- ` ```rescript`
- highlighted non-example forms such as ` ```res {4}`

## Rewrite Strategy

The script should collect enough location data from each matching `CodeTab` to support targeted rewrites:

- the `CodeTab` opening line
- the `CodeTab` closing line
- the ` ```res example` fence range
- the ` ```js` fence range when present

For each matching pair or insertable target, update mode should replace only the `JS Output` subsection and the single-label `CodeTab` header when needed. It should not reformat unrelated markdown or JSX.

## Malformed Cases

Malformed or ambiguous `CodeTab` structures should still warn instead of guessing. In particular:

- if a `CodeTab` contains a ` ```res example` block but the script cannot identify a safe insertion point for a new JS fence, it should warn and skip rewriting that block
- if a `CodeTab` has an unpaired partial JS section, the script should warn and skip rewriting that block rather than trying to repair it heuristically

## Documentation Updates

Update the README section that explains docs example checks so it documents both:

- the read-only check command: `node scripts/test-examples.mjs`
- the rewrite command: `node scripts/test-examples.mjs --update`

The README should say that update mode refreshes stale JS Output blocks and can create missing JS Output sections for eligible `CodeTab` examples.

## Verification Plan

Add automated coverage for:

- rewriting a stale existing JS Output fence
- filling an empty existing JS Output fence
- inserting a missing JS Output fence into a matching `CodeTab`
- upgrading `labels={["ReScript"]}` to `labels={["ReScript", "JS Output"]}` during update mode
- leaving multi-label tabs unchanged while still inserting or updating the JS fence
- preserving default-mode non-mutating behavior

Also verify the script manually with:

```sh
node scripts/test-examples.mjs
node scripts/test-examples.mjs --update
```

against temporary test fixtures and, if needed, a small real-doc sample.
