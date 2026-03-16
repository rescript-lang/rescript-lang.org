#!/usr/bin/env node
/**
 * postprocess-e2e.mjs
 *
 * Rewrites ReScript-compiled e2e test files so that Playwright can parse
 * fixture dependencies from the test callback signatures.
 *
 * Playwright calls `fn.toString()` on every test/hook callback and requires
 * the first parameter to use object destructuring syntax, e.g.:
 *
 *   async ({ page }) => { … }
 *
 * ReScript always compiles record-pattern arguments to a plain identifier:
 *
 *   async param => { … }
 *
 * This script rewrites every occurrence of `async param =>` to
 * `async ({ ...param }) =>` in the generated e2e .jsx files. Using object-rest
 * (`{ ...param }`) satisfies Playwright's `{…}` check while leaving the
 * callback body completely unchanged — `param.page` etc. continue to work
 * because `param` is still in scope with all the same properties.
 */

import { readFileSync, writeFileSync } from "node:fs";
import { readdir } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const e2eDir = join(__dirname, "..", "e2e");

const files = (await readdir(e2eDir)).filter((f) => f.endsWith(".test.jsx"));

if (files.length === 0) {
  console.error("postprocess-e2e: no .test.jsx files found in e2e/");
  process.exit(1);
}

for (const file of files) {
  const filePath = join(e2eDir, file);
  const original = readFileSync(filePath, "utf8");
  const rewritten = original.replaceAll(
    "async param =>",
    "async ({ ...param }) =>",
  );

  if (rewritten !== original) {
    writeFileSync(filePath, rewritten, "utf8");
    console.log(`postprocess-e2e: patched ${file}`);
  } else {
    console.log(`postprocess-e2e: no changes needed in ${file}`);
  }
}
