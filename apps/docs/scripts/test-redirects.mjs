import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const redirectsPath = path.resolve(__dirname, "../public/_redirects");

const entries = fs
  .readFileSync(redirectsPath, "utf8")
  .split(/\r?\n/)
  .map((line, index) => ({ index, line: line.trim() }))
  .filter(({ line }) => line !== "" && !line.startsWith("#"))
  .map(({ index, line }) => {
    const [source, destination, status] = line.split(/\s+/);
    return { index, source, destination, status };
  });

let findEntry = (source) => {
  const entry = entries.find((entry) => entry.source === source);
  assert.ok(entry, `Missing redirect for ${source}`);
  return entry;
};

let assertRedirect = (source, destination, status) => {
  const entry = findEntry(source);
  assert.equal(entry.destination, destination);
  assert.equal(entry.status, status);
  return entry;
};

assertRedirect("/llms/manual/llms.txt", "/llms.txt", "307");
const latestAlias = assertRedirect(
  "/llms/manual/latest/llms.txt",
  "/llms.txt",
  "307",
);
const nextAlias = assertRedirect(
  "/llms/manual/next/llms.txt",
  "/llms.txt",
  "307",
);

assert.ok(
  latestAlias.index < findEntry("/llms/manual/latest/*").index,
  "/llms/manual/latest/llms.txt must be listed before /llms/manual/latest/*",
);
assert.ok(
  nextAlias.index < findEntry("/llms/manual/next/*").index,
  "/llms/manual/next/llms.txt must be listed before /llms/manual/next/*",
);

console.log("✅ Redirect check complete. 0 issues found.");
