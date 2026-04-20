# Test Examples Update Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a real `--update` mode to `scripts/test-examples.mjs` that refreshes, fills, or inserts `JS Output` fences for eligible `CodeTab` examples.

**Architecture:** Keep the script line-oriented. Extend the `CodeTab` scanner to return enough metadata for targeted rewrites, thread an `update` flag through `run()`, and only mutate matching `CodeTab` blocks when explicitly requested. Cover stale, empty, missing, and single-label/multi-label cases with integration tests against temporary MDX fixtures.

**Tech Stack:** Node.js 22 ESM, `node:test`, `tinyglobby`, ReScript compiler CLI via `npm exec rescript build`

---

## File Map

- Modify: `scripts/test-examples.mjs`
  Responsibility: parse `--update`, collect rewrite metadata, refresh existing JS Output fences, insert missing fences, and rewrite `["ReScript"]` labels when needed.

- Modify: `scripts/__tests__/test-examples.test.mjs`
  Responsibility: prove update mode rewrites stale output, fills empty JS blocks, inserts missing JS blocks, and preserves custom multi-label titles.

- Modify: `README.md`
  Responsibility: document the read-only command and the new `--update` rewrite command.

- Modify: `docs/superpowers/plans/2026-04-20-test-examples-update-mode.md`
  Responsibility: this implementation plan.

### Task 1: Add Failing Update-Mode Tests

**Files:**

- Modify: `scripts/__tests__/test-examples.test.mjs`
- Test: `scripts/__tests__/test-examples.test.mjs`

- [ ] **Step 1: Write the failing tests**

Append these tests after the existing warning-focused cases:

```js
test("update rewrites a stale JS Output fence", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output"]}>

\`\`\`res example
let value = 1
\`\`\`

\`\`\`js
console.log("stale");
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.deepEqual(warnings, []);
  assert.match(nextContent, /var value = 1;/);
  assert.doesNotMatch(nextContent, /console\.log\("stale"\);/);
});

test("update fills an empty JS Output fence", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output"]}>

\`\`\`res example
let value = 1
\`\`\`

\`\`\`js
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.match(nextContent, /\`\`\`js\nvar value = 1;\n\`\`\`/);
});

test("update inserts a missing JS Output fence and upgrades a single ReScript label", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res example
let value = 1
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.match(nextContent, /labels=\{\["ReScript", "JS Output"\]\}/);
  assert.match(nextContent, /\`\`\`js\nvar value = 1;\n\`\`\`\n\n<\/CodeTab>/);
});

test("update inserts a missing JS Output fence without renaming a multi-label tab", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output (Module)"]}>

\`\`\`res example
let value = 1
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.match(
    nextContent,
    /labels=\{\["ReScript", "JS Output \(Module\)"\]\}/,
  );
  assert.match(nextContent, /\`\`\`js\nvar value = 1;\n\`\`\`/);
});
```

- [ ] **Step 2: Run the targeted test file to verify it fails**

Run: `node --test scripts/__tests__/test-examples.test.mjs`
Expected: FAIL because `run()` ignores the `update` option today and never rewrites the fixture files.

- [ ] **Step 3: Commit the red tests if desired**

```bash
git add scripts/__tests__/test-examples.test.mjs
git commit --no-gpg-sign -m "test: add update mode expectations"
```

### Task 2: Implement `--update` Rewrites

**Files:**

- Modify: `scripts/test-examples.mjs`
- Test: `scripts/__tests__/test-examples.test.mjs`

- [ ] **Step 1: Add minimal rewrite metadata collection**

In `scripts/test-examples.mjs`, introduce an internal `collectCodeTabTargets` helper that records:

```js
{
  tabStart: i,
  tabEnd: j,
  labels,
  labelLine: i,
  res: { line, content, fenceStart, fenceEnd },
  js: { content, fenceStart, fenceEnd, fenceKind } | null,
}
```

Then keep `collectCodeTabPairs` as a wrapper that maps those richer targets back to the existing `{pairs, warnings}` shape used by the current regression test.

- [ ] **Step 2: Thread an `update` flag through `run()` and the CLI**

Change `run()` to accept:

```js
export let run = ({
  docsRoot = path.join(projectRoot, "markdown-pages", "docs"),
  tempRoot = path.join(projectRoot, "temp"),
  logger = console,
  update = false,
} = {}) => {
```

and update the CLI entrypoint to call:

```js
let { success } = run({ update: process.argv.includes("--update") });
```

- [ ] **Step 3: Implement localized `CodeTab` rewrites**

Add a helper shaped like:

````js
let applyJsOutputUpdate = ({ lines, target, compiledJs }) => {
  let nextLines = [...lines];
  let jsLines = compiledJs === "" ? [] : compiledJs.split("\n");

  if (target.js != null) {
    nextLines.splice(
      target.js.fenceStart + 1,
      target.js.fenceEnd - target.js.fenceStart - 1,
      ...jsLines,
    );
  } else {
    nextLines.splice(target.tabEnd, 0, "", "```js", ...jsLines, "```", "");
  }

  if (target.labels.length === 1 && target.labels[0] === "ReScript") {
    nextLines[target.labelLine] =
      '<CodeTab labels={["ReScript", "JS Output"]}>';
  }

  return nextLines;
};
````

Use it only when `update === true`, and write the file back with `fs.writeFileSync(file, nextLines.join("\n"))` only if the content changed.

- [ ] **Step 4: Keep default mode read-only**

Preserve the current default-mode warning path:

```js
if (expectedJs !== currentJs) {
  logger.warn(
    `${file}:${pair.line} JS Output is stale. Run scripts/test-examples.mjs --update`,
  );
  warningCount++;
}
```

but gate the rewrite path behind `update`.

- [ ] **Step 5: Run the full test file to verify it passes**

Run: `node --test scripts/__tests__/test-examples.test.mjs`
Expected: PASS with all existing tests and the new update-mode tests green.

### Task 3: Document the New Command

**Files:**

- Modify: `README.md`
- Test: `README.md`

- [ ] **Step 1: Update the Markdown Codeblock Tests section**

Extend the README block from:

````md
Run the checks with:

```sh
node scripts/test-examples.mjs
```
````

````

to:

```md
Run the checks with:

```sh
node scripts/test-examples.mjs
````

Refresh stale or missing JS Output fences with:

```sh
node scripts/test-examples.mjs --update
```

````

- [ ] **Step 2: Review the diff for scope**

Run: `git diff -- scripts/test-examples.mjs scripts/__tests__/test-examples.test.mjs README.md`
Expected: only update-mode plumbing, rewrite logic, tests, and the README note appear.

- [ ] **Step 3: Commit**

```bash
git add scripts/test-examples.mjs scripts/__tests__/test-examples.test.mjs README.md docs/superpowers/plans/2026-04-20-test-examples-update-mode.md
git commit --no-gpg-sign -m "feat: add test examples update mode"
````
