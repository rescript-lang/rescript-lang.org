import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import { run } from "../test-examples.mjs";

let makeWorkspace = (
  content = `# Example

\`\`\`res example
let greeting = "hello"
\`\`\`
`,
) => {
  let root = fs.mkdtempSync(path.join(os.tmpdir(), "test-examples-"));
  let docsRoot = path.join(root, "markdown-pages", "docs");
  let tempRoot = path.join(root, "temp");
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
  assert.ok(logs.some((log) => log.includes("testing examples in")));
  assert.match(
    fs.readFileSync(path.join(tempRoot, "src", "_tempFile.res"), "utf-8"),
    /module M_0 = \{[\s\S]*let greeting = "hello"/,
  );
});
