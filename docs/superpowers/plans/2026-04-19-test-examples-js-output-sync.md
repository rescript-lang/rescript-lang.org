# Test Examples JS Output Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore `scripts/test-examples.mjs` so paired `JS Output` checks only apply to explicit ` ```res example` blocks.

**Architecture:** Keep the current importable runner and line-oriented scanner, but tighten the `CodeTab` pairing logic so it only captures runnable examples. Expose the scanner helper for direct testing, add one focused regression test that proves plain ` ```res` snippets inside matching `CodeTab` sections are ignored, then implement the minimal selector change and verify that targeted test.

**Tech Stack:** Node.js 22 ESM, `node:test`, `tinyglobby`, ReScript compiler CLI via `npm exec rescript build`

---

## File Map

- Modify: `scripts/test-examples.mjs`
  Responsibility: narrow JS Output pairing to ` ```res example` fences only while preserving the existing compile checks and warning behavior, and export the scanner helper used by the regression test.

- Modify: `scripts/__tests__/test-examples.test.mjs`
  Responsibility: cover the regression where plain ` ```res` fences inside matching `CodeTab` blocks should not be treated as runnable JS-sync examples.

- Modify: `docs/superpowers/plans/2026-04-19-test-examples-js-output-sync.md`
  Responsibility: this implementation plan.

### Task 1: Lock In The Regression With A Test

**Files:**

- Modify: `scripts/__tests__/test-examples.test.mjs`
- Test: `scripts/__tests__/test-examples.test.mjs`

- [ ] **Step 1: Write the failing test**

Expose `collectCodeTabPairs` from `scripts/test-examples.mjs`, then append this focused scanner test after the existing CodeTab-focused tests:

```js
import { collectCodeTabPairs, run } from "../test-examples.mjs";

test("collectCodeTabPairs ignores plain res fences inside a matching CodeTab", () => {
  let fixture = `# Demo

\`\`\`res example
let keepCompilerPathAlive = 1
\`\`\`

<CodeTab labels={["ReScript", "JS Output"]}>

\`\`\`res
let hiddenValue = 1
\`\`\`

\`\`\`js
console.log("leave me alone");
\`\`\`

</CodeTab>

<CodeTab labels={["ReScript", "JS Output"]}>

\`\`\`res example
let visibleValue = 2
\`\`\`

\`\`\`js
console.log("stale");
\`\`\`

</CodeTab>
`;

  let { pairs, warnings } = collectCodeTabPairs(fixture);

  assert.equal(warnings.length, 0);
  assert.equal(pairs.length, 1);
  assert.equal(pairs[0].res.content, "let visibleValue = 2");
  assert.equal(pairs[0].js.content, 'console.log("stale");');
});
```

- [ ] **Step 2: Run the test file to verify it fails**

Run: `node --test --test-name-pattern='collectCodeTabPairs ignores plain res fences inside a matching CodeTab' scripts/__tests__/test-examples.test.mjs`
Expected: FAIL because the current JS Output pairing logic starts from any ` ```res` fence, so it returns two pairs instead of one.

- [ ] **Step 3: Commit the red test if desired**

```bash
git add scripts/__tests__/test-examples.test.mjs
git commit --no-gpg-sign -m "test: capture plain res codetab regression"
```

### Task 2: Restrict JS Output Pairing To Explicit Examples

**Files:**

- Modify: `scripts/test-examples.mjs`
- Modify: `scripts/__tests__/test-examples.test.mjs`
- Test: `scripts/__tests__/test-examples.test.mjs`

- [ ] **Step 1: Write the minimal implementation**

In `scripts/test-examples.mjs`, replace the current fence classification used by `collectCodeTabPairs`:

````js
let fenceKind = (line) => {
  if (line.startsWith("```res")) {
    return "res";
  }

  if (line.startsWith("```js") || line.startsWith("```javascript")) {
    return "js";
  }

  return null;
};
````

with:

````js
let fenceKind = (line) => {
  if (line.startsWith("```res example")) {
    return "res-example";
  }

  if (line.startsWith("```js") || line.startsWith("```javascript")) {
    return "js";
  }

  return null;
};
````

Then update `collectCodeTabPairs` so it only starts a candidate pair when:

```js
if (kind === "res-example") {
```

and leave the rest of the pairing logic unchanged.

- [ ] **Step 2: Run the targeted regression test to verify it passes**

Run: `node --test --test-name-pattern='collectCodeTabPairs ignores plain res fences inside a matching CodeTab' scripts/__tests__/test-examples.test.mjs`
Expected: PASS with the focused regression test green.

- [ ] **Step 3: Review the diff for unintended scope**

Run: `git diff -- scripts/test-examples.mjs scripts/__tests__/test-examples.test.mjs`
Expected: only the new regression test and the selector narrowing appear. No unrelated behavior changes.

- [ ] **Step 4: Commit**

```bash
git add scripts/test-examples.mjs scripts/__tests__/test-examples.test.mjs docs/superpowers/plans/2026-04-19-test-examples-js-output-sync.md
git commit --no-gpg-sign -m "fix: limit JS output sync to example blocks"
```
