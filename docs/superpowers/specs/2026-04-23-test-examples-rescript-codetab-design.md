# ReScript-First CodeTab JS Output Expansion

## Summary

Expand `scripts/test-examples.mjs` so `--update` manages JS Output blocks for every `<CodeTab>` whose first label is `"ReScript"`, not just tabs already labeled `"JS Output"` or `"JS Output (Module)"`.

This change remains intentionally narrow:

- Only `CodeTab`s whose first label is `"ReScript"` are in scope.
- `TypeScript` output tabs are out of scope for now.
- Read-only mode stays silent on stale or missing JS output blocks.

## Problem

The current update logic only works reliably for a subset of ReScript docs patterns:

- `["ReScript", "JS Output"]`
- `["ReScript", "JS Output (Module)"]`
- `["ReScript"]` in the limited cases already supported by the current collector

That leaves other ReScript-first `CodeTab`s in an awkward state:

- tabs with a custom second label are not treated consistently
- tabs whose second fence is `ts` should be ignored, but that boundary is not explicit
- read-only mode should not emit noisy warnings for missing or stale JS output while formatting and presentation details are still in flux

## Goals

- Treat any `CodeTab` whose first label is `"ReScript"` as eligible for JS Output management.
- Keep `--update` as the only mode that inserts or rewrites JS output blocks.
- Add `"JS Output"` as the second label only when the tab currently has a single label, `["ReScript"]`.
- Preserve existing multi-label tab names exactly as written.
- Ignore ReScript-first tabs whose paired output fence is `ts`.

## Non-Goals

- Managing `CodeTab`s that do not start with `"ReScript"`.
- Validating or generating TypeScript output.
- Reintroducing stale JS Output warnings in read-only mode.
- Generalizing the system into a fully arbitrary multi-language tab synchronizer.

## Target Behavior

### ReScript-first tabs with one label

Input:

````mdx
<CodeTab labels={["ReScript"]}>

```res example
let value = 1
```

</CodeTab>
````

`--update` should:

- insert a `js` fence before `</CodeTab>`
- rewrite labels to `["ReScript", "JS Output"]`

### ReScript-first tabs with multiple labels and JS output

Input:

````mdx
<CodeTab labels={["ReScript", "Runtime"]}>

```res example
let value = 1
```

```js
console.log("stale");
```

</CodeTab>
````

`--update` should:

- rewrite the `js` fence contents from generated output
- leave `["ReScript", "Runtime"]` unchanged

### ReScript-first tabs with TypeScript output

Input:

````mdx
<CodeTab labels={["ReScript", "TypeScript Output"]}>

```res example
let value = 1
```

```ts
const value = 1;
```

</CodeTab>
````

This should be ignored for now:

- no warnings in read-only mode
- no changes in `--update`

## Read-Only Mode

When `run()` is called without `update: true`:

- keep compiling docs examples and reporting real compiler failures
- keep warning on malformed ReScript-first `CodeTab`s only where the structure is genuinely invalid for the supported JS-output flow
- do not warn for stale JS output blocks
- do not warn for missing JS output blocks
- do not warn for ignored TypeScript-output tabs

## Implementation Notes

- Broaden the `CodeTab` collector so target discovery keys off `labels[0] === "ReScript"`.
- Teach fence detection to distinguish `js`/`javascript` from `ts`/`typescript`.
- Treat a `ts` fence as an explicit skip signal for that `CodeTab`.
- Continue using the existing snippet compilation and boilerplate stripping for generated JS.
- Keep insertion behavior anchored to `</CodeTab>` so updates stay localized.

## Tests

Add or update tests for:

- single-label `ReScript` tabs getting a generated `js` fence plus a new `"JS Output"` label
- multi-label ReScript-first tabs with an existing `js` fence being updated without label rewrites
- ReScript-first tabs with a `ts` fence being ignored in both read-only and update modes
- read-only mode remaining silent on stale and missing JS output blocks

## Risks

- Some custom multi-label ReScript tabs may currently rely on loose pairing assumptions. The collector should stay conservative and only operate on clear ReScript-to-JS pairs.
- Skipping `ts` fences means some ReScript-first tabs will remain unmanaged until TypeScript output support is designed separately.

## Recommendation

Implement the narrow ReScript-first expansion now, keep TypeScript tabs excluded, and keep read-only mode silent. That gives broader `--update` coverage without reopening the noisy warning behavior or expanding into a generic tab synchronization system.
