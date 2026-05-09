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
section: "Overview"
order: 1
---

# Manual Introduction

\`\`\`res
let answer = 42
\`\`\`
`,
  );

  writeFile(
    root,
    "markdown-pages/docs/manual/overview.mdx",
    `---
title: "Language Overview"
section: "Language Features"
order: 1
---

# Language Overview

Language feature content.
`,
  );

  writeFile(
    root,
    "markdown-pages/docs/manual/bind-to-js-function.mdx",
    `---
title: "Bind to JS Function"
section: "JavaScript Interop"
order: 1
---

# Bind to JS Function

JavaScript interop content.
`,
  );

  writeFile(
    root,
    "markdown-pages/docs/manual/build-overview.mdx",
    `---
title: "Build Overview"
section: "Build System"
order: 1
---

# Build Overview

Build system content.
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
Version label: <MANUAL_VERSION_LABEL>

- [Complete documentation](https://rescript-lang.org/llms/manual/<VERSION>/llm-full.txt)
- [Abridged documentation](https://rescript-lang.org/llms/manual/<VERSION>/llm-small.txt)
- [Language overview](https://rescript-lang.org/llms/manual/language-overview/llm.txt)
- [JavaScript interop](https://rescript-lang.org/llms/manual/javascript-interop/llm.txt)
- [Build system](https://rescript-lang.org/llms/manual/build-system/llm.txt)
- [Getting started](https://rescript-lang.org/llms/manual/getting-started/llm.txt)
<MANUAL_VERSION_LINKS>
`,
  );
  writeFile(root, "public/llms/manual/llms.txt", "stale manual index");
  writeFile(root, "public/llms/manual/v10/llms.txt", "stale v10 index");
  writeFile(root, "public/llms/manual/v10/llm-full.txt", "stale v10 full");
  writeFile(root, "public/llms/manual/v10/llm-small.txt", "stale v10 small");
  writeFile(root, "public/llms/manual/v11/llms.txt", "stale v11 index");
  writeFile(root, "public/llms/manual/v11/llm-full.txt", "stale v11 full");
  writeFile(root, "public/llms/manual/v11/llm-small.txt", "stale v11 small");

  writeFile(
    root,
    "public/llms/manual/template.mdx",
    `---
title: "LLMs"
section: "Overview"
order: 4
---

# Manual LLMs

- [/llms/manual/<VERSION>/llm-full.txt](/llms/manual/<VERSION>/llm-full.txt)
- [/llms/manual/<VERSION>/llm-small.txt](/llms/manual/<VERSION>/llm-small.txt)
- [/llms/manual/language-overview/llm.txt](/llms/manual/language-overview/llm.txt)
- [/llms/manual/javascript-interop/llm.txt](/llms/manual/javascript-interop/llm.txt)
- [/llms/manual/build-system/llm.txt](/llms/manual/build-system/llm.txt)
- [/llms/manual/getting-started/llm.txt](/llms/manual/getting-started/llm.txt)
`,
  );

  writeFile(
    root,
    "public/llms/react/template.txt",
    `# React LLMs

Current version: <VERSION>
ReScript React package version: <RESCRIPT_REACT_VERSION>
React version: <REACT_VERSION>

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

let assertOccursInOrder = (content, parts) => {
  let lastIndex = -1;

  for (let part of parts) {
    let index = content.indexOf(part);
    assert.notEqual(index, -1);
    assert.ok(index > lastIndex);
    lastIndex = index;
  }
};

test("generate_llms writes the default manual index at the site root", () => {
  let root = makeWorkspace();

  child_process.execFileSync(process.execPath, [generatorPath], {
    cwd: root,
    stdio: "pipe",
  });

  let currentLlms = readFile(root, "public/llms.txt");
  let versionedLlms = readFile(root, "public/llms/manual/v12/llms.txt");
  let preReleaseLlms = readFile(root, "public/llms/manual/v13/llms.txt");
  let languageOverview = readFile(
    root,
    "public/llms/manual/language-overview/llm.txt",
  );
  let javascriptInterop = readFile(
    root,
    "public/llms/manual/javascript-interop/llm.txt",
  );
  let buildSystem = readFile(root, "public/llms/manual/build-system/llm.txt");
  let gettingStarted = readFile(
    root,
    "public/llms/manual/getting-started/llm.txt",
  );
  let manualVersions = ["v12", "v13"];

  assert.doesNotMatch(currentLlms, /<VERSION>/);
  assert.doesNotMatch(currentLlms, /<MANUAL_VERSION_LABEL>/);
  assert.match(currentLlms, /Current version: v12/);
  assert.match(currentLlms, /Version label: v12 \(current version\)/);
  assert.match(currentLlms, /v12 current/i);
  assert.match(currentLlms, /v13 pre-release/i);
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/manual\/v12\/llm-full\.txt/,
  );
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/manual\/v12\/llm-small\.txt/,
  );
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/manual\/language-overview\/llm\.txt/,
  );
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/manual\/javascript-interop\/llm\.txt/,
  );
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/manual\/build-system\/llm\.txt/,
  );
  assert.match(
    currentLlms,
    /https:\/\/rescript-lang\.org\/llms\/manual\/getting-started\/llm\.txt/,
  );
  assert.doesNotMatch(currentLlms, /\/llms\/manual\/v10\//);
  assert.doesNotMatch(currentLlms, /\/llms\/manual\/v11\//);
  assert.match(languageOverview, /# ReScript Language Overview/);
  assert.match(languageOverview, /Language feature content/);
  assert.doesNotMatch(languageOverview, /JavaScript interop content/);
  assert.doesNotMatch(languageOverview, /Manual Introduction/);
  assert.match(javascriptInterop, /# ReScript JavaScript Interop/);
  assert.match(javascriptInterop, /JavaScript interop content/);
  assert.doesNotMatch(javascriptInterop, /Language feature content/);
  assert.match(buildSystem, /# ReScript Build System/);
  assert.match(buildSystem, /Build system content/);
  assert.doesNotMatch(buildSystem, /Manual Introduction/);
  assert.match(gettingStarted, /# ReScript Getting Started/);
  assert.match(gettingStarted, /Manual Introduction/);
  assert.doesNotMatch(gettingStarted, /Manual LLMs/);
  assert.doesNotMatch(gettingStarted, /Build system content/);

  assert.equal(
    fs.existsSync(path.join(root, "public/llms/manual/llms.txt")),
    false,
  );
  assert.equal(
    fs.existsSync(path.join(root, "public/llms/manual/v10/llms.txt")),
    false,
  );
  assert.equal(
    fs.existsSync(path.join(root, "public/llms/manual/v10/llm-full.txt")),
    false,
  );
  assert.equal(
    fs.existsSync(path.join(root, "public/llms/manual/v10/llm-small.txt")),
    false,
  );
  assert.equal(
    fs.existsSync(path.join(root, "public/llms/manual/v11/llms.txt")),
    false,
  );
  assert.equal(
    fs.existsSync(path.join(root, "public/llms/manual/v11/llm-full.txt")),
    false,
  );
  assert.equal(
    fs.existsSync(path.join(root, "public/llms/manual/v11/llm-small.txt")),
    false,
  );
  assert.equal(versionedLlms, currentLlms);
  assert.match(preReleaseLlms, /Version label: v13 \(pre-release version\)/);

  for (let version of manualVersions) {
    assert.match(
      currentLlms,
      new RegExp(
        `https://rescript-lang\\.org/llms/manual/${version}/llm-full\\.txt`,
      ),
    );
    assert.equal(
      readFile(root, `public/llms/manual/${version}/llm-full.txt`),
      readFile(root, "public/llms/manual/llm-full.txt"),
    );
    assert.equal(
      readFile(root, `public/llms/manual/${version}/llm-small.txt`),
      readFile(root, "public/llms/manual/llm-small.txt"),
    );
    assert.equal(
      readFile(root, `public/llms/manual/${version}/language-overview/llm.txt`),
      languageOverview,
    );
    assert.equal(
      readFile(
        root,
        `public/llms/manual/${version}/javascript-interop/llm.txt`,
      ),
      javascriptInterop,
    );
    assert.equal(
      readFile(root, `public/llms/manual/${version}/build-system/llm.txt`),
      buildSystem,
    );
    assert.equal(
      readFile(root, `public/llms/manual/${version}/getting-started/llm.txt`),
      gettingStarted,
    );
    assert.match(
      readFile(root, `public/llms/manual/${version}/llms.txt`),
      new RegExp(`Current version: ${version}`),
    );
  }

  assert.doesNotMatch(currentLlms, /v10\.|v11\.|v12\.|v13\./);
  let majorVersionLinks = currentLlms.slice(
    currentLlms.indexOf("v13 pre-release LLMs index"),
  );
  assertOccursInOrder(majorVersionLinks, [
    "/llms/manual/v13/llm-full.txt",
    "/llms/manual/v12/llm-full.txt",
  ]);
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
  assert.doesNotMatch(currentLlms, /<RESCRIPT_REACT_VERSION>|<REACT_VERSION>/);
  assert.match(currentLlms, /Current version: v0\.14\.2/);
  assert.match(currentLlms, /ReScript React package version: v0\.14\.2/);
  assert.match(currentLlms, /React version: v19\.2\.4/);
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
