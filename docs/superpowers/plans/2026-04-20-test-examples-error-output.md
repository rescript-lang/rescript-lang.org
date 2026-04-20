# Test Examples Error Output Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `scripts/test-examples.mjs` print clean ReScript compiler errors for bad docs examples without dumping raw Node exception output.

**Architecture:** Keep the current compile flow but add one shared formatter/reporter for compiler failures. Cover both the whole-file example compile path and the snippet compile path used during JS Output syncing, then thread the cleaned reporting through the existing catches without changing the underlying validation behavior.

**Tech Stack:** Node.js 22 ESM, `node:test`, `tinyglobby`, ReScript compiler CLI via `npm exec rescript build`

---

## File Map

- Modify: `scripts/test-examples.mjs`
  Responsibility: format compiler stderr into markdown-focused output, suppress raw Node exception dumps, and reuse the reporting logic in both compile paths.

- Modify: `scripts/__tests__/test-examples.test.mjs`
  Responsibility: prove compile failures are reported as cleaned ReScript output without raw Node stack traces.

- Modify: `docs/superpowers/plans/2026-04-20-test-examples-error-output.md`
  Responsibility: this implementation plan.

### Task 1: Capture the Failure Output With a Test

**Files:**

- Modify: `scripts/__tests__/test-examples.test.mjs`
- Test: `scripts/__tests__/test-examples.test.mjs`

- [ ] **Step 1: Write the failing test**

Append a focused test that creates a bad docs fixture and asserts on the logger output:

````js
test("run reports cleaned compiler errors without raw Node stack traces", () => {
  let fixture = `# Demo

\`\`\`res example
type person = {name: string}
type person = {age: int}
\`\`\`
`;

  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger });

  assert.equal(result.success, false);
  assert.ok(warnings.some((warning) => warning.includes("sample.mdx")));
  assert.ok(
    warnings.some((warning) =>
      warning.includes("Multiple definition of the type name person"),
    ),
  );
  assert.ok(warnings.some((warning) => warning.includes("```res example")));
  assert.ok(
    !warnings.some((warning) => warning.includes("Error: Command failed")),
  );
  assert.ok(!warnings.some((warning) => warning.includes("node:internal")));
});
````

- [ ] **Step 2: Run the targeted test to verify it fails**

Run: `node --test --test-name-pattern='run reports cleaned compiler errors without raw Node stack traces' scripts/__tests__/test-examples.test.mjs`
Expected: FAIL because the current script does not report through `logger.warn` for file-level compile failures and still relies on the raw thrown child-process error path.

- [ ] **Step 3: Commit the red test if desired**

```bash
git add scripts/__tests__/test-examples.test.mjs
git commit --no-gpg-sign -m "test: capture docs compiler error formatting"
```

### Task 2: Format Compiler Errors in the Script

**Files:**

- Modify: `scripts/test-examples.mjs`
- Test: `scripts/__tests__/test-examples.test.mjs`

- [ ] **Step 1: Add formatting helpers**

In `scripts/test-examples.mjs`, add helpers shaped like:

````js
let tempFileRegex = /_tempFile\.res/g;

let formatCompilerError = ({ file, error }) => {
  let stderr =
    error?.stderr == null
      ? String(error?.message ?? "Unknown compiler error")
      : error.stderr.toString();

  return stderr
    .replace(tempFileRegex, path.relative(".", file))
    .replace(
      /\/\* _MODULE_(EXAMPLE|PRELUDE|SIG)_START \*\/.+/g,
      (_, capture) =>
        "```res " +
        (capture === "EXAMPLE"
          ? "example"
          : capture === "PRELUDE"
            ? "prelude"
            : "sig"),
    )
    .replace(
      /(.*)\}(.*)\/\/ _MODULE_END/g,
      (_, before, after) => `${before}\`\`\`${after}`,
    )
    .replace(/Error: Command failed:[\s\S]*$/m, "")
    .trim();
};

let reportCompilerError = ({ logger, file, line, error }) => {
  logger.warn(`${file}${line == null ? "" : `:${line}`}`);
  logger.warn(formatCompilerError({ file, error }));
};
````

- [ ] **Step 2: Use the reporter in the file-level compile catch**

Replace the current bare catch:

```js
    } catch {
      success = false;
      return;
    }
```

with:

```js
    } catch (error) {
      reportCompilerError({ logger, file, error });
      success = false;
      return;
    }
```

- [ ] **Step 3: Catch and report snippet compile failures**

Wrap the snippet compile call:

```js
let compiledJs = compileSnippet(tempRoot, snippetSource);
```

as:

```js
let compiledJs;
try {
  compiledJs = compileSnippet(tempRoot, snippetSource);
} catch (error) {
  reportCompilerError({ logger, file, line: target.line, error });
  success = false;
  break;
}
```

This should stop processing the current file once one snippet compile fails, while still keeping the output docs-focused.

- [ ] **Step 4: Run the full test file to verify it passes**

Run: `node --test scripts/__tests__/test-examples.test.mjs`
Expected: PASS with the new error-formatting test and the existing update-mode tests green.

### Task 3: Review Scope and Commit

**Files:**

- Modify: `scripts/test-examples.mjs`
- Modify: `scripts/__tests__/test-examples.test.mjs`
- Modify: `docs/superpowers/plans/2026-04-20-test-examples-error-output.md`

- [ ] **Step 1: Review the scoped diff**

Run: `git diff -- scripts/test-examples.mjs scripts/__tests__/test-examples.test.mjs docs/superpowers/plans/2026-04-20-test-examples-error-output.md`
Expected: only the new formatter/reporter logic and the new compile-failure test appear.

- [ ] **Step 2: Commit**

```bash
git add scripts/test-examples.mjs scripts/__tests__/test-examples.test.mjs docs/superpowers/plans/2026-04-20-test-examples-error-output.md
git commit --no-gpg-sign -m "fix: clean test examples compiler errors"
```
