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
    fs.readFileSync(path.join(tempRoot, "src", "Example.res"), "utf-8"),
    /module M_0 = \{[\s\S]*let greeting = "hello"/,
  );
});

test("run compiles examples without requiring npm on PATH", () => {
  let { docsRoot, tempRoot } = makeWorkspace();
  let { logger } = makeLogger();
  let originalPath = process.env.PATH;

  process.env.PATH = path.join(os.tmpdir(), "missing-npm");

  try {
    let result = run({ docsRoot, tempRoot, logger });

    assert.equal(result.success, true);
    assert.equal(result.warningCount, 0);
  } finally {
    process.env.PATH = originalPath;
  }
});

test("run compiles a plain res fence as checked code", () => {
  let fixture = `# Demo

\`\`\`res
let greeting = "hello"
\`\`\`
`;

  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger });
  let tempFile = fs.readFileSync(
    path.join(tempRoot, "src", "Example.res"),
    "utf8",
  );

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.match(tempFile, /module M_0 = \{[\s\S]*let greeting = "hello"/);
});

test("run ignores a res nocheck fence during page-level compile checks", () => {
  let fixture = `# Demo

\`\`\`res prelude
let helper = 1
\`\`\`

\`\`\`res
let greeting = "hello"
\`\`\`

\`\`\`res nocheck
let ignored = "nope"
\`\`\`
`;

  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger });
  let tempFile = fs.readFileSync(
    path.join(tempRoot, "src", "Example.res"),
    "utf8",
  );

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.match(tempFile, /module M_0 = \{[\s\S]*let greeting = "hello"/);
  assert.doesNotMatch(tempFile, /ignored/);
});

test("update inserts JS Output for a single-label ReScript CodeTab with a plain res fence", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res
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
    /<CodeTab labels=\{\["ReScript", "JS Output"\]\}>[\s\S]*```res\nlet value = 1\n```[\s\S]*```js[\s\S]*let value = 1;[\s\S]*<\/CodeTab>/,
  );
});

test("update emits Example instead of _tempFile for component-style snippets", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res
@react.component
let make = () => <div> {React.string("Hello")} </div>
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(nextContent, /function Example\(props\)/);
  assert.match(nextContent, /let make = Example;/);
  assert.doesNotMatch(nextContent, /_tempFile/);
});

test("update ignores a res nocheck fence inside a ReScript CodeTab", () => {
  let fixture = `# Demo

\`\`\`res prelude
let helper = 1
\`\`\`

<CodeTab labels={["ReScript"]}>

\`\`\`res
let visibleValue = 1
\`\`\`

</CodeTab>

<CodeTab labels={["ReScript"]}>

\`\`\`res nocheck
type person = {name: string}
type person = {age: int}
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
    /<CodeTab labels=\{\["ReScript", "JS Output"\]\}>[\s\S]*```res\nlet visibleValue = 1\n```[\s\S]*<\/CodeTab>/,
  );
  assert.match(
    nextContent,
    /<CodeTab labels=\{\["ReScript"\]\}>[\s\S]*```res nocheck[\s\S]*type person = \{name: string\}[\s\S]*type person = \{age: int\}[\s\S]*<\/CodeTab>/,
  );
  assert.doesNotMatch(
    nextContent,
    /<CodeTab labels=\{\["ReScript"\]\}>[\s\S]*```js/,
  );
});

test("update ignores ReScript CodeTabs whose second label is TypeScript Output", () => {
  let fixture = `# Demo

\`\`\`res prelude
let helper = 1
\`\`\`

<CodeTab labels={["ReScript"]}>

\`\`\`res
let visibleValue = 1
\`\`\`

</CodeTab>

<CodeTab labels={["ReScript", "TypeScript Output"]}>

\`\`\`res
let value = 1
\`\`\`

\`\`\`ts
export const value: number
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
    /<CodeTab labels=\{\["ReScript", "JS Output"\]\}>[\s\S]*```res\nlet visibleValue = 1\n```[\s\S]*```js[\s\S]*let visibleValue = 1;[\s\S]*<\/CodeTab>/,
  );
  assert.match(
    nextContent,
    /<CodeTab labels=\{\["ReScript", "TypeScript Output"\]\}>[\s\S]*```res\nlet value = 1\n```[\s\S]*```ts\nexport const value: number\n```[\s\S]*<\/CodeTab>/,
  );
  assert.doesNotMatch(
    nextContent,
    /<CodeTab labels=\{\["ReScript", "TypeScript Output"\]\}>[\s\S]*```js/,
  );
});

test("update adds JSX Preserved Output for a JSX-producing single-label ReScript CodeTab", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res
let view = <div className="greeting"> {React.string("Hello")} </div>
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(
    nextContent,
    /labels=\{\["ReScript", "JS Output", "JSX Preserved Output"\]\}/,
  );
  assert.match(nextContent, /\`\`\`js[\s\S]*JsxRuntime\./);
  assert.match(nextContent, /\`\`\`jsx/);
  assert.match(nextContent, /<div[\s\S]*className[\s\S]*Hello/);
});

test("update appends JSX Preserved Output without renaming JS Output (Module)", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output (Module)"]}>

\`\`\`res
let view = <div> {React.string("Hello")} </div>
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(
    nextContent,
    /labels=\{\["ReScript", "JS Output \(Module\)", "JSX Preserved Output"\]\}/,
  );
  assert.match(nextContent, /\`\`\`js[\s\S]*JsxRuntime\./);
  assert.match(nextContent, /\`\`\`jsx/);
});

test("update removes an existing JSX Preserved Output tab when runtime JS no longer uses JsxRuntime", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output", "JSX Preserved Output"]}>

\`\`\`res
let value = 1
\`\`\`

\`\`\`js
console.log("stale runtime");
\`\`\`

\`\`\`jsx
<div>{"stale preserve"}</div>;
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(nextContent, /labels=\{\["ReScript", "JS Output"\]\}/);
  assert.doesNotMatch(nextContent, /JSX Preserved Output/);
  assert.doesNotMatch(nextContent, /\`\`\`jsx/);
});

test("update ignores JSX preserved output generation for res nocheck fences", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res nocheck
let view = <div> {React.string("Hello")} </div>
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(nextContent, /labels=\{\["ReScript"\]\}/);
  assert.doesNotMatch(nextContent, /\`\`\`js/);
  assert.doesNotMatch(nextContent, /\`\`\`jsx/);
});

test("run reports cleaned compiler errors without raw Node stack traces", () => {
  let fixture = `# Demo

\`\`\`res
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
  assert.ok(warnings.some((warning) => warning.includes("```res")));
  assert.ok(!warnings.some((warning) => warning.includes("```res example")));
  assert.ok(
    !warnings.some((warning) => warning.includes("Error: Command failed")),
  );
  assert.ok(!warnings.some((warning) => warning.includes("node:internal")));
});

test("ignores stale JS Output blocks without rewriting the file", () => {
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
  assert.equal(result.warningCount, 0);
  assert.deepEqual(warnings, []);
  assert.match(nextContent, /console\.log\("stale"\);/);
});

test("update emits ESM JS Output fences", () => {
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
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(nextContent, /export \{\n  value,\n\}/);
  assert.doesNotMatch(nextContent, /exports\.value = value;/);
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
  assert.match(nextContent, /export \{\n  value,\n\}/);
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
  assert.match(nextContent, /export \{\n  value,\n\}/);
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
  assert.match(nextContent, /export \{\n  value,\n\}/);
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
  assert.match(nextContent, /export \{\n  value,\n\}/);
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

test("collectCodeTabPairs collects plain res fences in a checked ReScript CodeTab", () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output"]}>

\`\`\`res
let visibleValue = 1
\`\`\`

\`\`\`js
console.log("stale");
\`\`\`

</CodeTab>

<CodeTab labels={["ReScript", "TypeScript Output"]}>

\`\`\`res nocheck
let ignoredValue = 2
\`\`\`

\`\`\`ts
export const ignoredValue: number
\`\`\`

</CodeTab>
`;

  let { pairs, warnings } = collectCodeTabPairs(fixture);

  assert.equal(warnings.length, 0);
  assert.equal(pairs.length, 1);
  assert.equal(pairs[0].res.content, "let visibleValue = 1");
  assert.equal(pairs[0].js.content, 'console.log("stale");');
  assert.doesNotMatch(
    fixture,
    /<CodeTab labels=\{\["ReScript", "TypeScript Output"\]\}>[\s\S]*```js/,
  );
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
