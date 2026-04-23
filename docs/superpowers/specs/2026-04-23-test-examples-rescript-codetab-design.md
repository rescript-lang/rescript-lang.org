# ReScript Fence Checking And CodeTab JS Output Expansion

## Summary

Migrate the docs example checker from an opt-in ` ```res example ` model to a default-checked ` ```res ` model.

After this change:

- plain ` ```res ` fences are checked by default
- ` ```res nocheck ` is the explicit opt-out from both page-level compile checks and `CodeTab` JS-output handling
- `--update` manages JS output for ReScript-first `CodeTab`s using checked `res` fences
- docs content is migrated away from ` ```res example `

This keeps the authoring model simpler: checked ReScript is the default, and opting out is explicit.

## Problem

The current checker contract is split across two different concepts:

- page-level compile checks only include ` ```res example `, ` ```res prelude `, and ` ```res sig `
- `CodeTab` JS-output handling also depends on ` ```res example `

That causes two practical problems:

1. Checked code is opt-in instead of default. Authors have to remember a special `example` marker rather than writing ordinary `res` fences.
2. Existing ReScript-first `CodeTab`s already use plain ` ```res ` in some places, so the current JS-output updater cannot handle all of the real docs shapes without either changing the checker contract or rewriting those blocks first.

The requested direction is to invert that default:

- plain `res` should be checked
- `nocheck` should be the explicit escape hatch
- docs should be migrated to the simpler fence form

## Goals

- Make plain ` ```res ` the default checked ReScript fence.
- Add ` ```res nocheck ` as an explicit opt-out from page-level compile checks.
- Make ` ```res nocheck ` also opt out of `CodeTab` JS-output handling.
- Update `CodeTab` JS-output collection so it works from checked ` ```res ` fences inside ReScript-first tabs.
- Keep `res prelude` and `res sig` behavior intact.
- Keep `TypeScript Output` tabs excluded from JS-output handling.
- Migrate docs content from ` ```res example ` to ` ```res ` where those fences are intended to stay checked.

## Non-Goals

- Managing `CodeTab`s that do not start with `"ReScript"`.
- Validating or generating TypeScript output.
- Reintroducing stale JS-output warnings in read-only mode.
- Designing a generic multi-language tab synchronization system.

## New Fence Contract

### Checked ReScript

````mdx
```res
let value = 1
```
````

This fence participates in page-level compile checks.

If it appears as the ReScript block inside a supported `CodeTab`, it also participates in JS-output generation during `--update`.

### Explicit opt-out

````mdx
```res nocheck
<NotAllowed {...props1} {...props2} />
```
````

This fence is ignored by:

- page-level compile checks
- `CodeTab` JS-output handling

### Existing special fences

These keep their current meaning:

- ` ```res prelude `
- ` ```res sig `

## CodeTab Scope

Only `CodeTab`s whose first label is `"ReScript"` are in scope.

Current ReScript-first label shapes in the docs tree:

- `["ReScript", "JS Output"]`
- `["ReScript", "JS Output (Module)"]`
- `["ReScript"]`
- `["ReScript", "TypeScript Output"]`

Behavior rules:

- If the first label is not `"ReScript"`, ignore the `CodeTab`.
- If the second label is `"TypeScript Output"`, ignore the `CodeTab`.
- If the tab has only `["ReScript"]`, `--update` should insert a `js` fence and rewrite labels to `["ReScript", "JS Output"]`.
- If the tab already has a second label other than `"TypeScript Output"`, preserve that label exactly as written.
- Any third or later labels are ignored when deciding JS-output eligibility.

## Target Behavior

### Single-label ReScript tab

Input:

````mdx
<CodeTab labels={["ReScript"]}>

```res
let value = 1
```

</CodeTab>
````

`--update` should:

- insert a generated ` ```js ` fence
- rewrite labels to `["ReScript", "JS Output"]`

### Existing JS Output tab

Input:

````mdx
<CodeTab labels={["ReScript", "JS Output (Module)"]}>

```res
let value = 1
```

```js
console.log("stale");
```

</CodeTab>
````

`--update` should:

- rewrite the `js` fence contents
- leave the labels unchanged

### Extra labels

Input:

````mdx
<CodeTab labels={["ReScript", "JS Output", "Notes"]}>

```res
let value = 1
```

```js
console.log("stale");
```

</CodeTab>
````

`--update` should:

- rewrite the `js` fence contents
- decide participation from the first two labels only
- leave all labels unchanged

### TypeScript output tab

Input:

````mdx
<CodeTab labels={["ReScript", "TypeScript Output"]}>

```res
@genType
let value = 1
```

```ts
export const value: number;
```

</CodeTab>
````

This should be ignored:

- no warnings in read-only mode
- no changes in `--update`

### Nocheck inside a ReScript CodeTab

Input:

````mdx
<CodeTab labels={["ReScript"]}>

```res nocheck
<NotAllowed {...props1} {...props2} />
```

</CodeTab>
````

This should be ignored:

- no page-level compile attempt for that fence
- no JS-output insertion or rewrite

## Read-Only Mode

When `run()` is called without `update: true`:

- keep compiling checked ReScript fences at the page level
- keep reporting real compiler failures
- keep warning on structurally malformed supported `CodeTab`s only where the checker genuinely cannot interpret a managed JS-output shape
- do not warn for stale JS-output blocks
- do not warn for missing JS-output blocks
- do not warn for ignored `TypeScript Output` or `nocheck` tabs

## Migration

The implementation should migrate checked docs fences from:

- ` ```res example `

to:

- ` ```res `

This migration should only affect fences that are meant to stay checked.

Any currently unchecked or intentionally invalid examples should use:

- ` ```res nocheck `

The initial docs migration should cover the docs tree the script scans now:

- `markdown-pages/docs/manual`
- `markdown-pages/docs/react`

## Implementation Notes

- Update page parsing so plain `res` fences are recognized as checked code.
- Exclude `res nocheck` from page-level module wrapping and compile input.
- Update `CodeTab` fence detection so managed ReScript blocks come from checked `res` fences rather than `res example`.
- Keep `res prelude` and `res sig` special handling unchanged.
- Continue distinguishing `js`/`javascript` from `ts`/`typescript`.
- Treat either `labels[1] === "TypeScript Output"` or a `res nocheck` source fence as an explicit skip signal for JS-output handling.
- Keep insertion anchored to `</CodeTab>`.

## Tests

Add or update tests for:

- plain `res` fences participating in page-level compile checks
- `res nocheck` fences being excluded from page-level compile checks
- single-label `ReScript` tabs with plain `res` getting a generated `js` fence and a new `"JS Output"` label
- existing ReScript/JS-output tabs continuing to update from plain `res` fences without label rewrites
- ReScript-first tabs with `"TypeScript Output"` being ignored
- `res nocheck` inside a ReScript-first `CodeTab` being ignored in both read-only and update modes
- read-only mode remaining silent on stale and missing JS-output blocks

## Risks

- The docs migration may touch a large number of files, so the tests need to lock down the new fence contract before bulk updates run.
- Some currently plain `res` fences may be intentionally invalid teaching examples; those need to be converted to `res nocheck` during migration instead of becoming newly failing checked code.
- If any future second-label variants appear, they will need an explicit decision rather than accidental inference.

## Recommendation

Implement the contract change in three phases:

1. lock down the new `res`/`res nocheck` behavior in tests
2. update the checker and `CodeTab` collector to use the new defaults
3. run a docs migration from `res example` to `res`, converting any intentional non-checkable examples to `res nocheck`

That sequence keeps the behavioral change explicit and makes the bulk docs rewrite much safer.
