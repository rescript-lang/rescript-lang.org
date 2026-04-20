import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import { collectCodeTabPairs, run } from "../test-examples.mjs";

let makeWorkspace = (
  content = `# Example

\`\`\`res example
let greeting = "hello"
\`\`\`
`,
) => {
  let root = fs.mkdtempSync(path.join(os.tmpdir(), "test examples-"));
  let docsRoot = path.join(root, "markdown-pages", "docs");
  let tempRoot = path.join(root, "temp workspace");
  let file = path.join(docsRoot, "manual", "sample.mdx");

  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content);

  return { root, docsRoot, tempRoot, file };
};

let makeLogger = () => {
  let logs = [];
  let warnings = [];

  return {
    logger: {
      log: (...parts) => logs.push(parts.join(" ")),
      warn: (...parts) => warnings.push(parts.join(" ")),
    },
    logs,
    warnings,
  };
};

test("run compiles a real example block from an injected workspace", () => {
  let { docsRoot, tempRoot } = makeWorkspace();
  let { logger, logs } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger });

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.ok(tempRoot.includes(" "));
  assert.ok(logs.some((log) => log.includes("testing examples in")));
  assert.match(
    fs.readFileSync(path.join(tempRoot, "src", "_tempFile.res"), "utf-8"),
    /module M_0 = \{[\s\S]*let greeting = "hello"/,
  );
});

test("warns about stale JS Output blocks without rewriting the file", () => {
  let fixture = `# Demo

<div className="hidden">

\`\`\`res prelude
@val external alert: string => unit = "alert"
\`\`\`

</div>

<CodeTab labels={["ReScript", "JS Output"]}>

\`\`\`res example
alert("hello")
\`\`\`

\`\`\`js
console.log("stale");
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 1);
  assert.match(warnings[0], /sample\.mdx/);
  assert.match(warnings[0], /--update/);
  assert.match(nextContent, /console\.log\("stale"\);/);
});

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
  assert.match(nextContent, /let value = 1;/);
  assert.match(nextContent, /exports\.value = value;/);
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
  let { logger, warnings } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.deepEqual(warnings, []);
  assert.match(nextContent, /\`\`\`js/);
  assert.match(nextContent, /let value = 1;/);
  assert.match(nextContent, /exports\.value = value;/);
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
  let { logger, warnings } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.deepEqual(warnings, []);
  assert.match(nextContent, /labels=\{\["ReScript", "JS Output"\]\}/);
  assert.match(nextContent, /\`\`\`js/);
  assert.match(nextContent, /let value = 1;/);
  assert.match(nextContent, /exports\.value = value;/);
  assert.match(nextContent, /\`\`\`\n\n<\/CodeTab>/);
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
  let { logger, warnings } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.deepEqual(warnings, []);
  assert.match(
    nextContent,
    /labels=\{\["ReScript", "JS Output \(Module\)"\]\}/,
  );
  assert.match(nextContent, /\`\`\`js/);
  assert.match(nextContent, /let value = 1;/);
  assert.match(nextContent, /exports\.value = value;/);
});

test("ignores standalone javascript fences outside a matching CodeTab", () => {
  let fixture = `# Demo

\`\`\`res example
let value = 1
\`\`\`

\`\`\`js
console.log("leave me alone");
\`\`\`
`;

  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger });

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
});

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

test("warns and skips malformed CodeTabs that never provide a JS Output fence", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output"]}>

\`\`\`res example
let value = 1
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger });

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 1);
  assert.match(warnings[0], /missing paired JS Output block/);
});
