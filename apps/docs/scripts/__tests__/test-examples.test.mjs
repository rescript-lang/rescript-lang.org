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

test("run compiles a real example block from an injected workspace", async () => {
  let { docsRoot, tempRoot } = makeWorkspace();
  let { logger, logs } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger });

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.ok(tempRoot.includes(" "));
  assert.ok(logs.some((log) => log.includes("testing examples in")));
  assert.match(
    fs.readFileSync(path.join(tempRoot, "src", "Example.res"), "utf-8"),
    /module M_0 = \{[\s\S]*let greeting = "hello"/,
  );
});

test("run compiles examples without requiring npm on PATH", async () => {
  let { docsRoot, tempRoot } = makeWorkspace();
  let { logger } = makeLogger();
  let originalPath = process.env.PATH;

  process.env.PATH = path.join(os.tmpdir(), "missing-npm");

  try {
    let result = await run({ docsRoot, tempRoot, logger });

    assert.equal(result.success, true);
    assert.equal(result.warningCount, 0);
  } finally {
    process.env.PATH = originalPath;
  }
});

test("run compiles a plain res fence as checked code", async () => {
  let fixture = `# Demo

\`\`\`res
let greeting = "hello"
\`\`\`
`;

  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger });
  let tempFile = fs.readFileSync(
    path.join(tempRoot, "src", "Example.res"),
    "utf8",
  );

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.match(tempFile, /module M_0 = \{[\s\S]*let greeting = "hello"/);
});

test("run ignores a res nocheck fence during page-level compile checks", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger });
  let tempFile = fs.readFileSync(
    path.join(tempRoot, "src", "Example.res"),
    "utf8",
  );

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.match(tempFile, /module M_0 = \{[\s\S]*let greeting = "hello"/);
  assert.doesNotMatch(tempFile, /ignored/);
});

test("update inserts JS Output for a single-label ReScript CodeTab with a plain res fence", async () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res
let value = 1
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.match(
    nextContent,
    /<CodeTab labels=\{\["ReScript", "JS Output"\]\}>[\s\S]*```res\nlet value = 1\n```[\s\S]*```js[\s\S]*let value = 1;[\s\S]*<\/CodeTab>/,
  );
});

test("update emits Example instead of _tempFile for component-style snippets", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(nextContent, /function Example\(props\)/);
  assert.match(nextContent, /let make = Example;/);
  assert.doesNotMatch(nextContent, /_tempFile/);
});

test("update ignores a res nocheck fence inside a ReScript CodeTab", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger, update: true });
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

test("update ignores ReScript CodeTabs whose second label is TypeScript Output", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger, update: true });
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

test("update adds JSX Preserved Output for a JSX-producing single-label ReScript CodeTab", async () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res
let view = <div className="greeting"> {React.string("Hello")} </div>
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger, update: true });
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

test("update appends JSX Preserved Output without renaming JS Output (Module)", async () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output (Module)"]}>

\`\`\`res
let view = <div> {React.string("Hello")} </div>
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(
    nextContent,
    /labels=\{\["ReScript", "JS Output \(Module\)", "JSX Preserved Output"\]\}/,
  );
  assert.match(nextContent, /\`\`\`js[\s\S]*JsxRuntime\./);
  assert.match(nextContent, /\`\`\`jsx/);
});

test("update removes an existing JSX Preserved Output tab when runtime JS no longer uses JsxRuntime", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(nextContent, /labels=\{\["ReScript", "JS Output"\]\}/);
  assert.doesNotMatch(nextContent, /JSX Preserved Output/);
  assert.doesNotMatch(nextContent, /\`\`\`jsx/);
});

test("update ignores JSX preserved output generation for res nocheck fences", async () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res nocheck
let view = <div> {React.string("Hello")} </div>
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(nextContent, /labels=\{\["ReScript"\]\}/);
  assert.doesNotMatch(nextContent, /\`\`\`js/);
  assert.doesNotMatch(nextContent, /\`\`\`jsx/);
});

test("run reports cleaned compiler errors without raw Node stack traces", async () => {
  let fixture = `# Demo

\`\`\`res
type person = {name: string}
type person = {age: int}
\`\`\`
`;

  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger });

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

test("fails stale JS Output blocks without rewriting the file", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, false);
  assert.equal(result.warningCount, 0);
  assert.equal(result.mismatchCount, 1);
  assert.match(warnings[0], /sample\.mdx:\d+ stale JS Output/);
  assert.equal(nextContent, fixture);
  assert.match(nextContent, /console\.log\("stale"\);/);
});

test("update emits ESM JS Output fences", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.match(nextContent, /export \{ value \};/);
  assert.doesNotMatch(nextContent, /exports\.value = value;/);
});

test("update rewrites a stale JS Output fence", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.deepEqual(warnings, []);
  assert.match(nextContent, /let value = 1;/);
  assert.match(nextContent, /export \{ value \};/);
  assert.doesNotMatch(nextContent, /console\.log\("stale"\);/);
});

test("update fills an empty JS Output fence", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.deepEqual(warnings, []);
  assert.match(nextContent, /\`\`\`js/);
  assert.match(nextContent, /let value = 1;/);
  assert.match(nextContent, /export \{ value \};/);
});

test("update inserts a missing JS Output fence and upgrades a single ReScript label", async () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript"]}>

\`\`\`res example
let value = 1
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger, update: true });
  let nextContent = fs.readFileSync(file, "utf8");

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
  assert.deepEqual(warnings, []);
  assert.match(nextContent, /labels=\{\["ReScript", "JS Output"\]\}/);
  assert.match(nextContent, /\`\`\`js/);
  assert.match(nextContent, /let value = 1;/);
  assert.match(nextContent, /export \{ value \};/);
  assert.match(nextContent, /\`\`\`\n\n<\/CodeTab>/);
});

test("update inserts a missing JS Output fence without renaming a multi-label tab", async () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output (Module)"]}>

\`\`\`res example
let value = 1
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger, update: true });
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
  assert.match(nextContent, /export \{ value \};/);
});

test("ignores standalone javascript fences outside a matching CodeTab", async () => {
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

  let result = await run({ docsRoot, tempRoot, logger });

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
});

test("collectCodeTabPairs collects plain res fences in a checked ReScript CodeTab", async () => {
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

test("fails malformed CodeTabs that never provide a JS Output fence", async () => {
  let fixture = `# Demo

<CodeTab labels={["ReScript", "JS Output"]}>

\`\`\`res example
let value = 1
\`\`\`

</CodeTab>
`;

  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();

  let result = await run({ docsRoot, tempRoot, logger });

  assert.equal(result.success, false);
  assert.equal(result.warningCount, 1);
  assert.match(warnings[0], /missing paired JS Output block/);
});

let outputTab = (
  source,
  { label = "ReScript", fence = "res", output = "console.log('stale');" } = {},
) => `
<CodeTab labels={["${label}", "JS Output"]}>

\`\`\`${fence}
${source}
\`\`\`

\`\`\`js
${output}
\`\`\`

</CodeTab>
`;

for (let fence of ["rescript", "res prelude"]) {
  test(`checks and updates ${fence} output tabs with custom source labels`, async () => {
    let fixture = outputTab("let value = 1", { fence, label: "Source" });
    let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
    let { logger } = makeLogger();
    assert.equal((await run({ docsRoot, tempRoot, logger })).mismatchCount, 1);
    assert.equal(
      (await run({ docsRoot, tempRoot, logger, update: true })).success,
      true,
    );
    assert.match(fs.readFileSync(file, "utf8"), /export \{ value \};/);
    assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
  });
}

test("accepts formatted output differences without rewriting the page", async () => {
  let fixture = outputTab('let value = "hello"', {
    output: "let value='hello'\nexport {value}\n",
  });
  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
  assert.equal(fs.readFileSync(file, "utf8"), fixture);
});

test("checks and updates both ESM and CommonJS output without changing their labels", async () => {
  let fixture = outputTab("let value = 1")
    .replace(
      '["ReScript", "JS Output"]',
      '["ReScript", "JS Output (Module)", "JS Output (CommonJS)"]',
    )
    .replace("</CodeTab>", "```js\nexports.value = 0;\n```\n\n</CodeTab>");
  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  assert.equal((await run({ docsRoot, tempRoot, logger })).mismatchCount, 2);
  assert.equal(
    (await run({ docsRoot, tempRoot, logger, update: true })).success,
    true,
  );
  let updated = fs.readFileSync(file, "utf8");
  assert.match(updated, /JS Output \(Module\).*JS Output \(CommonJS\)/);
  assert.match(updated, /export \{ value \};/);
  assert.match(updated, /exports.value = value;/);
  assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
  fs.writeFileSync(
    file,
    updated.replace("exports.value = value;", "exports.value = 0;"),
  );
  assert.equal((await run({ docsRoot, tempRoot, logger })).mismatchCount, 1);
});

test("checks preserved JSX and produces stable tab ordering on repeated updates", async () => {
  let { docsRoot, tempRoot, file } = makeWorkspace(
    outputTab('let view = <div> {React.string("Hello")} </div>'),
  );
  let { logger } = makeLogger();
  assert.equal(
    (await run({ docsRoot, tempRoot, logger, update: true })).success,
    true,
  );
  let updated = fs.readFileSync(file, "utf8");
  assert.match(updated, /```js[\s\S]*```jsx/);
  assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
  assert.equal(
    (await run({ docsRoot, tempRoot, logger, update: true })).success,
    true,
  );
  assert.equal(fs.readFileSync(file, "utf8"), updated);
  fs.writeFileSync(
    file,
    updated.replace('<div>{"Hello"}</div>', '<div>{"Stale"}</div>'),
  );
  let { logger: checkLogger, warnings } = makeLogger();
  let result = await run({ docsRoot, tempRoot, logger: checkLogger });
  assert.equal(result.success, false);
  assert.equal(result.mismatchCount, 1);
  assert.match(warnings[0], /stale JSX Preserved Output/);
});

test("checks indented fences and keeps indentation when updating output", async () => {
  let fixture = outputTab("let value = 1", { fence: "rescript" })
    .split("\n")
    .map((line) => (line ? "  " + line : line))
    .join("\n");
  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  assert.equal((await run({ docsRoot, tempRoot, logger })).mismatchCount, 1);
  assert.equal(
    (await run({ docsRoot, tempRoot, logger, update: true })).success,
    true,
  );
  assert.match(fs.readFileSync(file, "utf8"), /  ```js\n  let value = 1;/);
  assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
});

test("supports multiline CodeTab labels and fences longer than three backticks", async () => {
  let fixture = outputTab("let value = 1")
    .replace(
      '<CodeTab labels={["ReScript", "JS Output"]}>',
      '<CodeTab\n  labels={[\n    "ReScript",\n    "JS Output"\n  ]}\n>',
    )
    .replaceAll("```", "````");
  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  assert.equal(
    (await run({ docsRoot, tempRoot, logger, update: true })).success,
    true,
  );
  assert.match(fs.readFileSync(file, "utf8"), /````js\nlet value = 1;/);
  assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
});

for (let fence of ["rescript", "resi", "res sig"]) {
  test(`compiles ${fence} fences and reports invalid types`, async () => {
    let fixture = `\`\`\`${fence}\n${fence === "rescript" ? "let value: missingType = 1" : "let value: missingType"}\n\`\`\`\n`;
    let { docsRoot, tempRoot } = makeWorkspace(fixture);
    let { logger, warnings } = makeLogger();
    assert.equal((await run({ docsRoot, tempRoot, logger })).success, false);
    assert.ok(warnings.some((warning) => warning.includes("missingType")));
  });
}

test("compiles a valid resi signature alongside checked examples", async () => {
  let fixture =
    "```resi\ntype t\nlet value: t\n```\n\n```res\nlet value = 1\n```\n";
  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
});

for (let [name, change, message] of [
  [
    "spaced closing tag",
    (content) => content.replace("</CodeTab>", "</ CodeTab>"),
    /malformed CodeTab closing tag/,
  ],
  [
    "missing closing tag",
    (content) => content.replace("</CodeTab>", ""),
    /unclosed CodeTab/,
  ],
  [
    "missing code fence",
    (content) => content.replace("```js\nconsole.log('stale');\n```", ""),
    /missing paired JS Output/,
  ],
  [
    "invalid labels",
    (content) =>
      content.replace('["ReScript", "JS Output"]', '["ReScript", invalid]'),
    /invalid CodeTab labels/,
  ],
]) {
  test(`fails a ${name} without updating the page`, async () => {
    let fixture = change(outputTab("let value = 1"));
    let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
    let { logger, warnings } = makeLogger();
    let result = await run({ docsRoot, tempRoot, logger });
    assert.equal(result.success, false);
    assert.ok(warnings.some((warning) => message.test(warning)));
    assert.equal(fs.readFileSync(file, "utf8"), fixture);
  });
}

test("never rewrites a page with malformed closing tags in update mode", async () => {
  let fixture = outputTab("let value = 1").replace("</CodeTab>", "</ CodeTab>");
  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  assert.equal(
    (await run({ docsRoot, tempRoot, logger, update: true })).success,
    false,
  );
  assert.equal(fs.readFileSync(file, "utf8"), fixture);
});

test("does not treat CodeTab tags inside a code fence as markup", async () => {
  let fixture =
    "````mdx\n" +
    outputTab("let value = 1").replace("</CodeTab>", "</ CodeTab>") +
    "\n````\n";
  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  let result = await run({ docsRoot, tempRoot, logger });
  assert.equal(result.success, true);
  assert.equal(result.checkedFiles, 0);
});

test("includes guides and syntax lookup in the default checks", async () => {
  let { docsRoot, tempRoot } = makeWorkspace();
  let guide = path.join(docsRoot, "guides", "sample.mdx");
  let syntax = path.join(docsRoot, "..", "syntax-lookup", "sample.mdx");
  for (let file of [guide, syntax]) {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, outputTab("let value = 1"));
  }
  let { logger, warnings } = makeLogger();
  let result = await run({ docsRoot, tempRoot, logger });
  assert.equal(result.success, false);
  assert.equal(result.checkedFiles, 3);
  assert.equal(result.mismatchCount, 2);
  assert.ok(warnings.some((warning) => warning.includes("guides")));
  assert.ok(warnings.some((warning) => warning.includes("syntax-lookup")));
});

test("reports skipped historical blogs and audits them without rewriting in update mode", async () => {
  let { docsRoot, tempRoot } = makeWorkspace();
  let blog = path.join(docsRoot, "..", "blog", "release-old.mdx");
  let fixture = outputTab("let value = 1");
  fs.mkdirSync(path.dirname(blog), { recursive: true });
  fs.writeFileSync(blog, fixture);
  let { logger, logs } = makeLogger();
  let result = await run({ docsRoot, tempRoot, logger });
  assert.equal(result.success, true);
  assert.equal(result.skippedFiles, 1);
  assert.ok(logs.some((log) => log.includes("historical blog")));
  result = await run({
    docsRoot,
    tempRoot,
    logger,
    includeBlog: true,
    update: true,
  });
  assert.equal(result.success, false);
  assert.equal(result.mismatchCount, 1);
  assert.equal(result.skippedFiles, 0);
  assert.equal(fs.readFileSync(blog, "utf8"), fixture);
});

test("checks output for comparison tabs with multiple ReScript spellings", async () => {
  let fixture = outputTab("let value = 1", { label: "Primary" })
    .replace(
      '["Primary", "JS Output"]',
      '["Primary", "Equivalent", "JS Output"]',
    )
    .replace("```js", "```res\nlet value = 1 + 0\n```\n\n```js");
  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  let result = await run({ docsRoot, tempRoot, logger });
  assert.equal(result.warningCount, 0);
  assert.equal(result.mismatchCount, 1);
  assert.equal(
    (await run({ docsRoot, tempRoot, logger, update: true })).success,
    true,
  );
  assert.match(fs.readFileSync(file, "utf8"), /Equivalent/);
  assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
});

test("does not drop code between compiler annotation comments and the purity footer", async () => {
  let fixture = outputTab("let value = 1", {
    output:
      "/* explanatory comment */\nlet value = 0;\nexport { value };\n/* No side effect */",
  });
  let { docsRoot, tempRoot } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  let result = await run({ docsRoot, tempRoot, logger });
  assert.equal(result.success, false);
  assert.equal(result.mismatchCount, 1);
});

test("keeps prelude context when a checked example shadows a module", async () => {
  let fixture =
    "```res prelude\nmodule Helper = { let value = 1 }\nlet context = 2\n```\n" +
    outputTab(
      "module Helper = { let value = 3 }\nlet value = Helper.value + context",
    );
  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger } = makeLogger();
  let result = await run({ docsRoot, tempRoot, logger });
  assert.equal(result.errorCount, 0);
  assert.equal(result.mismatchCount, 1);
  assert.equal(
    (await run({ docsRoot, tempRoot, logger, update: true })).success,
    true,
  );
  assert.match(fs.readFileSync(file, "utf8"), /let value = 5;/);
  assert.equal((await run({ docsRoot, tempRoot, logger })).success, true);
});

test("fails unclosed ReScript fences without rewriting the page", async () => {
  let fixture = "```res\nlet value = 1\n";
  let { docsRoot, tempRoot, file } = makeWorkspace(fixture);
  let { logger, warnings } = makeLogger();
  let result = await run({ docsRoot, tempRoot, logger, update: true });
  assert.equal(result.success, false);
  assert.equal(result.warningCount, 1);
  assert.match(warnings[0], /unclosed code fence/);
  assert.equal(fs.readFileSync(file, "utf8"), fixture);
});
