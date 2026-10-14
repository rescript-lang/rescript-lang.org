import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function checkRedirects({
  redirectsPath = path.resolve(__dirname, "../public/_redirects"),
  publicDirectory = path.resolve(__dirname, "../public"),
} = {}) {
  const entries = fs
    .readFileSync(redirectsPath, "utf8")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line !== "" && !line.startsWith("#"))
    .map((line) => {
      const [source, destination, status] = line.split(/\s+/);
      return { source, destination, status };
    });

  const assertRedirect = (source, destination, status) => {
    const entry = entries.find((entry) => entry.source === source);
    assert.ok(entry, `Missing redirect for ${source}`);
    assert.equal(entry.destination, destination, source);
    assert.equal(entry.status, status, source);
    return entry;
  };

  const assertTextTarget = (source, destination) => {
    // Cloudflare uses the first matching rule, including wildcard rules.
    const entry = entries.find(({ source: pattern }) =>
      pattern.endsWith("*")
        ? source.startsWith(pattern.slice(0, -1))
        : pattern === source,
    );
    assert.ok(entry, `Missing redirect for ${source}`);
    const splat = source.slice(entry.source.length - 1);
    assert.equal(
      entry.destination.replace(":splat", splat),
      destination,
      `First matching redirect for ${source}`,
    );
    assert.equal(entry.status, "307", source);

    const target = path.join(publicDirectory, destination.slice(1));
    assert.ok(
      fs.existsSync(target) && fs.statSync(target).isFile(),
      `Missing generated LLM text file for ${source}: ${destination}`,
    );
    assert.ok(
      fs.readFileSync(target, "utf8").trim().length > 0,
      `Empty generated LLM text file: ${destination}`,
    );
  };

  assertRedirect(
    "/docs/guidelines/publishing-packages",
    "/docs/guides/publishing-packages",
    "308",
  );

  const textFiles = [
    ["llms.txt", "/llms.txt"],
    ["llms-full.txt", "/llms/manual/llm-full.txt"],
    ["llms-small.txt", "/llms/manual/llm-small.txt"],
  ];
  for (const [file, destination] of textFiles) {
    const source = `/llms/manual/${file}`;
    assertRedirect(source, destination, "307");
    assertTextTarget(source, destination);
  }

  for (const alias of [
    "latest",
    "next",
    "v13.0.0",
    "v13",
    "v12.0.0",
    "v12",
    "v11.0.0",
    "v11",
    "v10",
  ]) {
    const prefix = `/llms/manual/${alias}`;
    for (const [file, destination] of textFiles) {
      const source = `${prefix}/${file}`;
      assertRedirect(source, destination, "307");
      assertTextTarget(source, destination);
    }
    assertRedirect(`${prefix}/*`, "/llms/manual/:splat", "307");
    for (const file of [
      "llm-full.txt",
      "llm-small.txt",
      "language-overview/llm.txt",
      "javascript-interop/llm.txt",
      "build-system/llm.txt",
      "getting-started/llm.txt",
    ]) {
      assertTextTarget(`${prefix}/${file}`, `/llms/manual/${file}`);
    }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  checkRedirects();
  console.log("✅ Redirect check complete. 0 issues found.");
}
