# ReScript-First CodeTab JS Output Expansion

## Summary

Expand `scripts/test-examples.mjs` so `--update` manages JS Output blocks for every `<CodeTab>` whose first label is `"ReScript"`, including single-label tabs that should gain a default `"JS Output"` partner.

This change remains intentionally narrow:

- Only `CodeTab`s whose first label is `"ReScript"` are in scope.
- `TypeScript` output tabs are out of scope for now.
- Read-only mode stays silent on stale or missing JS output blocks.

## Problem

The current docs tree contains four ReScript-first `CodeTab` shapes:

- `["ReScript", "JS Output"]`
- `["ReScript", "JS Output (Module)"]`
- `["ReScript"]`
- `["ReScript", "TypeScript Output"]`

The desired behavior is narrow and data-driven:

- single-label ReScript tabs should gain a default JS output tab during `--update`
- tabs whose second label is `TypeScript Output` should be ignored for now
- any third or later labels should not affect JS-output handling
- read-only mode should not emit noisy warnings for missing or stale JS output while formatting and presentation details are still in flux

## Goals

- Treat any `CodeTab` whose first label is `"ReScript"` as eligible for JS Output management.
- Keep `--update` as the only mode that inserts or rewrites JS output blocks.
- Add `"JS Output"` as the second label only when the tab currently has a single label, `["ReScript"]`.
- Preserve existing second and later labels exactly as written.
- Ignore ReScript-first tabs whose second label is `"TypeScript Output"`.
- Ignore any third or later labels when deciding whether a tab participates in JS-output handling.

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

### ReScript-first tabs with existing JS output labels

Input:

````mdx
<CodeTab labels={["ReScript", "JS Output (Module)"]}>

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
- leave `["ReScript", "JS Output (Module)"]` unchanged

### ReScript-first tabs with extra labels

Input:

````mdx
<CodeTab labels={["ReScript", "JS Output", "Notes"]}>

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
- decide participation from the first two labels only
- leave all labels exactly as written

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
- do not let extra labels change JS-output handling

## Implementation Notes

- Broaden the `CodeTab` collector so target discovery keys off `labels[0] === "ReScript"`.
- Treat `labels[1] === "TypeScript Output"` as an explicit skip signal for that `CodeTab`.
- Teach fence detection to distinguish `js`/`javascript` from `ts`/`typescript`.
- Continue using the existing snippet compilation and boilerplate stripping for generated JS.
- Keep insertion behavior anchored to `</CodeTab>` so updates stay localized.
- Ignore `labels[2...]` when deciding whether a tab is eligible for JS-output handling.

## Tests

Add or update tests for:

- single-label `ReScript` tabs getting a generated `js` fence plus a new `"JS Output"` label
- existing `["ReScript", "JS Output"]` and `["ReScript", "JS Output (Module)"]` tabs continuing to update without label rewrites
- ReScript-first tabs with `"TypeScript Output"` being ignored in both read-only and update modes
- ReScript-first tabs with extra labels being handled based on the first two labels only
- read-only mode remaining silent on stale and missing JS output blocks

## Risks

- If future docs introduce new second-label variants, they will need an explicit decision instead of being inferred accidentally.
- Skipping `ts` fences means some ReScript-first tabs will remain unmanaged until TypeScript output support is designed separately.

## Recommendation

Implement the narrow ReScript-first expansion now, keep TypeScript tabs excluded, and keep read-only mode silent. That gives broader `--update` coverage without reopening the noisy warning behavior or expanding into a generic tab synchronization system.
