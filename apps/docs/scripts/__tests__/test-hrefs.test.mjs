import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(new URL("../test-hrefs.mjs", import.meta.url));

const check = (markdown) => {
  const fixture = fs.mkdtempSync(path.join(os.tmpdir(), "rescript-hrefs-"));
  try {
    // remark-validate-links discovers the repository root and URL through Git.
    execFileSync("git", ["init", "--quiet"], { cwd: fixture });
    execFileSync(
      "git",
      [
        "remote",
        "add",
        "origin",
        "https://github.com/rescript-lang/rescript-lang.org.git",
      ],
      { cwd: fixture },
    );
    const apiDir = path.join(fixture, "markdown-pages/docs/api");
    const manualDir = path.join(fixture, "markdown-pages/docs/manual");
    fs.mkdirSync(apiDir, { recursive: true });
    fs.mkdirSync(manualDir, { recursive: true });
    for (const library of ["stdlib", "belt", "dom"]) {
      fs.writeFileSync(
        path.join(apiDir, `${library}.json`),
        JSON.stringify({ [library]: {}, [`${library}/example`]: {} }),
      );
    }
    fs.writeFileSync(path.join(manualDir, "api.mdx"), markdown);
    return spawnSync(process.execPath, [script], {
      cwd: fixture,
      env: { ...process.env, CI: "1" },
      encoding: "utf8",
    });
  } finally {
    fs.rmSync(fixture, { recursive: true, force: true });
  }
};

test("accepts API routes generated from the JSON data", () => {
  const result = check(`
[Stdlib](/docs/manual/api/stdlib)
[Dom](/docs/manual/api/dom)
[Nested module](/docs/manual/api/belt/example/)
[API entry](/docs/manual/api/stdlib/example#value-get)
`);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /0 issues found/);
});

test("rejects the broken DOM route even beside valid API links", () => {
  const result = check(`
[Stdlib](/docs/manual/api/stdlib)
[Dom](/docs/manual/api/stdlibdom)
`);
  assert.equal(result.status, 1, result.stdout + result.stderr);
  assert.match(result.stdout, /Cannot find file.*stdlibdom/);
});

test("rejects API module typos and unrelated missing pages", () => {
  for (const href of [
    "/docs/manual/api/stdlib/typo",
    "/docs/manual/missing-page",
    "./nested/docs/manual/api/dom",
  ]) {
    const result = check(`
[Valid API](/docs/manual/api/dom)
[Missing page](${href})
`);
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stdout, /Cannot find file/);
  }
});
