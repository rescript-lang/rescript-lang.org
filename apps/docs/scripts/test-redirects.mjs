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

let assertManualLlmsVersionRedirects = (sourceVersion, destinationVersion) => {
  const sourcePrefix = `/llms/manual/${sourceVersion}`;
  const destinationPrefix = `/llms/manual/${destinationVersion}`;
  const index = assertRedirect(
    `${sourcePrefix}/llms.txt`,
    `${destinationPrefix}/llms.txt`,
    "307",
  );
  const full = assertRedirect(
    `${sourcePrefix}/llms-full.txt`,
    `${destinationPrefix}/llm-full.txt`,
    "307",
  );
  const small = assertRedirect(
    `${sourcePrefix}/llms-small.txt`,
    `${destinationPrefix}/llm-small.txt`,
    "307",
  );
  const wildcard = assertRedirect(
    `${sourcePrefix}/*`,
    `${destinationPrefix}/:splat`,
    "307",
  );

  assert.ok(
    index.index < wildcard.index,
    `${sourcePrefix}/llms.txt must be listed before ${sourcePrefix}/*`,
  );
  assert.ok(
    full.index < wildcard.index,
    `${sourcePrefix}/llms-full.txt must be listed before ${sourcePrefix}/*`,
  );
  assert.ok(
    small.index < wildcard.index,
    `${sourcePrefix}/llms-small.txt must be listed before ${sourcePrefix}/*`,
  );
};

assertRedirect("/llms/manual/llms.txt", "/llms.txt", "307");
assertRedirect(
  "/docs/guidelines/publishing-packages",
  "/docs/guides/publishing-packages",
  "308",
);
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
assertManualLlmsVersionRedirects("v13.0.0", "v13");
assertManualLlmsVersionRedirects("v12.0.0", "v12");
assertManualLlmsVersionRedirects("v11", "v12");
assertManualLlmsVersionRedirects("v11.0.0", "v12");

assert.ok(
  latestAlias.index < findEntry("/llms/manual/latest/*").index,
  "/llms/manual/latest/llms.txt must be listed before /llms/manual/latest/*",
);
assert.ok(
  nextAlias.index < findEntry("/llms/manual/next/*").index,
  "/llms/manual/next/llms.txt must be listed before /llms/manual/next/*",
);

console.log("✅ Redirect check complete. 0 issues found.");
