import test from "node:test";
import assert from "node:assert/strict";
import child_process from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const docsRoot = path.resolve(__dirname, "../..");
const generatorPath = path.join(docsRoot, "_scripts", "generate_llms.mjs");

let writeFile = (root, filePath, content) => {
  let fullPath = path.join(root, filePath);
  fs.mkdirSync(path.dirname(fullPath), { recursive: true });
  fs.writeFileSync(fullPath, content);
};

let makeWorkspace = () => {
  let root = fs.mkdtempSync(path.join(os.tmpdir(), "generate llms-"));

  writeFile(
    root,
    "markdown-pages/docs/manual/introduction.mdx",
    `---
title: "Introduction"
---

# Manual Introduction

\`\`\`res
let answer = 42
\`\`\`
`,
  );

  writeFile(
    root,
    "markdown-pages/docs/react/introduction.mdx",
    `---
title: "React Introduction"
---

# React Introduction
`,
  );

  writeFile(
    root,
    "public/llms/manual/template.txt",
    `# Manual LLMs

Current version: <VERSION>

- [Complete documentation](https://rescript-lang.org/llms/manual/<VERSION>/llm-full.txt)
- [Abridged documentation](https://rescript-lang.org/llms/manual/<VERSION>/llm-small.txt)
`,
  );
  writeFile(root, "public/llms/manual/llms.txt", "stale manual index");

  writeFile(
    root,
    "public/llms/manual/template.mdx",
    `# Manual LLMs

- [/llms/manual/<VERSION>/llm-full.txt](/llms/manual/<VERSION>/llm-full.txt)
- [/llms/manual/<VERSION>/llm-small.txt](/llms/manual/<VERSION>/llm-small.txt)
`,
  );

  writeFile(
    root,
    "public/llms/react/template.txt",
    `# React LLMs

Current version: <VERSION>

- [Complete documentation](https://rescript-lang.org/llms/react/<VERSION>/llm-full.txt)
- [Abridged documentation](https://rescript-lang.org/llms/react/<VERSION>/llm-small.txt)
`,
  );

  writeFile(
    root,
    "public/llms/react/template.mdx",
    `# React LLMs

- [/llms/react/<VERSION>/llm-full.txt](/llms/react/<VERSION>/llm-full.txt)
- [/llms/react/<VERSION>/llm-small.txt](/llms/react/<VERSION>/llm-small.txt)
`,
  );

  return root;
};

let readFile = (root, filePath) =>
  fs.readFileSync(path.join(root, filePath), "utf8");

test("generate_llms writes the default manual index at the site root", () => {
  let root = makeWorkspace();

  child_process.execFileSync(process.execPath, [generatorPath], {
    cwd: root,
    stdio: "pipe",
  });

  let currentLlms = readFile(root, "public/llms.txt");
  let versionedLlms = readFile(root, "public/llms/manual/v12/llms.txt");

  assert.doesNotMatch(currentLlms, /<VERSION>/);
  assert.match(currentLlms, /Current version: v12/);
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/manual\/v12\/llm-full\.txt/,
  );
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/manual\/v12\/llm-small\.txt/,
  );

  assert.equal(
    fs.existsSync(path.join(root, "public/llms/manual/llms.txt")),
    false,
  );
  assert.equal(versionedLlms, currentLlms);
  assert.equal(
    readFile(root, "public/llms/manual/v12/llm-full.txt"),
    readFile(root, "public/llms/manual/llm-full.txt"),
  );
  assert.equal(
    readFile(root, "public/llms/manual/v12/llm-small.txt"),
    readFile(root, "public/llms/manual/llm-small.txt"),
  );
});

test("generate_llms writes versioned ReScript React files", () => {
  let root = makeWorkspace();

  child_process.execFileSync(process.execPath, [generatorPath], {
    cwd: root,
    stdio: "pipe",
  });

  let currentLlms = readFile(root, "public/llms/react/llms.txt");
  let versionedLlms = readFile(root, "public/llms/react/v0.14.2/llms.txt");

  assert.doesNotMatch(currentLlms, /<VERSION>/);
  assert.match(currentLlms, /Current version: v0\.14\.2/);
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/react\/v0\.14\.2\/llm-full\.txt/,
  );
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/react\/v0\.14\.2\/llm-small\.txt/,
  );

  assert.equal(
    fs.existsSync(path.join(root, "public/llms/react/latest/llms.txt")),
    false,
  );
  assert.equal(versionedLlms, currentLlms);
  assert.equal(
    readFile(root, "public/llms/react/v0.14.2/llm-full.txt"),
    readFile(root, "public/llms/react/llm-full.txt"),
  );
  assert.equal(
    readFile(root, "public/llms/react/v0.14.2/llm-small.txt"),
    readFile(root, "public/llms/react/llm-small.txt"),
  );
});
