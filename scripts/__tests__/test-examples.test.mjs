import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

import { run } from "../test-examples.mjs";

let makeWorkspace = (content = "# Empty\n") => {
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

test("run accepts injected docs and temp roots without exiting the process", () => {
  let { docsRoot, tempRoot } = makeWorkspace();
  let { logger } = makeLogger();

  let result = run({ docsRoot, tempRoot, logger });

  assert.equal(result.success, true);
  assert.equal(result.warningCount, 0);
});
