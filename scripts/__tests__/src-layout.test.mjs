import test from "node:test";
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "../..");

function trackedTopLevelSrcFiles() {
  let files = execFileSync("git", ["ls-files", "src"], {
    cwd: projectRoot,
    encoding: "utf8",
  })
    .trim()
    .split("\n")
    .filter(Boolean);

  return files.filter((file) => path.dirname(file) === "src");
}

test("tracked source files do not live at the top level of src", () => {
  assert.deepEqual(trackedTopLevelSrcFiles(), []);
});
