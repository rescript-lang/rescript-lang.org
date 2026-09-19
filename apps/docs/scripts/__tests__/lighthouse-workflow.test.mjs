import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { lighthouseArtifactName } from "../lighthouse-report.mjs";

const scriptDirectory = fileURLToPath(
  new URL("../../../../.github/scripts/", import.meta.url),
);

async function fixture(context, overrides = {}) {
  const directory = await mkdtemp(path.join(tmpdir(), "lighthouse-workflow-"));
  context.after(() => rm(directory, { recursive: true, force: true }));
  await mkdir(path.join(directory, "bin"));
  await writeFile(
    path.join(directory, "bin/gh"),
    `#!${process.execPath}
const fs = require("node:fs");
const args = process.argv.slice(2);
fs.appendFileSync(process.env.CALLS, JSON.stringify(args) + "\\n");
if (process.env.GH_FAIL === "1") process.exit(1);
if (args.some(arg => arg.endsWith("/zip"))) {
  process.stdout.write(fs.readFileSync(process.env.ARCHIVE));
} else if (!args.includes("DELETE")) {
  process.stdout.write(process.env.GH_RESPONSE || "");
}
`,
    { mode: 0o755 },
  );
  await writeFile(
    path.join(directory, "bin/unzip"),
    `#!${process.execPath}
require("node:fs").appendFileSync(process.env.CALLS, JSON.stringify(["unzip", ...process.argv.slice(2)]) + "\\n");
`,
    { mode: 0o755 },
  );
  return {
    directory,
    env: {
      ...process.env,
      PATH: `${directory}/bin:${process.env.PATH}`,
      CALLS: path.join(directory, "calls.jsonl"),
      GITHUB_ENV: path.join(directory, "environment"),
      GITHUB_EVENT_NAME: "pull_request",
      GITHUB_REPOSITORY: "owner/site",
      PR_NUMBER: "1355",
      RAW_BRANCH: "Perf/Homepage",
      LIGHTHOUSE_TARGET_BRANCH: "master",
      LIGHTHOUSE_TARGET_ARTIFACT_NAME: lighthouseArtifactName("master"),
      LIGHTHOUSE_ARTIFACT_NAME: lighthouseArtifactName("Perf/Homepage"),
      CURRENT_ARTIFACT_ID: "20",
      RUNNER_TEMP: directory,
      ...overrides,
    },
  };
}

function run(script, { directory, env }) {
  return spawnSync("bash", [path.join(scriptDirectory, script)], {
    cwd: directory,
    env,
    encoding: "utf8",
  });
}

async function calls({ env }) {
  return (await readFile(env.CALLS, "utf8"))
    .trim()
    .split("\n")
    .map((line) => JSON.parse(line));
}

test("environment uses the PR's live target branch and existing artifact keys", async (context) => {
  const state = await fixture(context, { GH_RESPONSE: "release/current\n" });
  const result = run("lighthouse-environment.sh", state);
  assert.equal(result.status, 0, result.stderr);
  const environment = await readFile(state.env.GITHUB_ENV, "utf8");
  assert.ok(environment.includes("LIGHTHOUSE_BRANCH=Perf/Homepage\n"));
  assert.ok(environment.includes("LIGHTHOUSE_TARGET_BRANCH=release/current\n"));
  assert.ok(
    environment.includes(
      `LIGHTHOUSE_TARGET_ARTIFACT_NAME=${lighthouseArtifactName("release/current")}\n`,
    ),
  );
  assert.ok(
    environment.includes(
      `LIGHTHOUSE_ARTIFACT_NAME=${lighthouseArtifactName("Perf/Homepage")}\n`,
    ),
  );
  assert.ok(environment.includes("SAFE_BRANCH=perf-homepage\n"));
  assert.ok(
    environment.includes(
      "VITE_DEPLOYMENT_URL=https://perf-homepage.rescript-lang.pages.dev\n",
    ),
  );
  assert.deepEqual(await calls(state), [
    ["api", "/repos/owner/site/pulls/1355", "--jq", ".base.ref"],
  ]);
});

test("production uses its own baseline without a PR lookup", async (context) => {
  const state = await fixture(context, {
    GITHUB_EVENT_NAME: "push",
    RAW_BRANCH: "master",
    GH_FAIL: "1",
  });
  assert.equal(run("lighthouse-environment.sh", state).status, 0);
  const environment = await readFile(state.env.GITHUB_ENV, "utf8");
  assert.ok(environment.includes("LIGHTHOUSE_TARGET_BRANCH=master\n"));
  assert.ok(environment.includes("VITE_DEPLOYMENT_URL=\n"));
  assert.ok(!environment.includes("SAFE_BRANCH="));
});

test("missing target artifacts are allowed", async (context) => {
  const state = await fixture(context);
  const result = run("lighthouse-restore.sh", state);
  assert.equal(result.status, 0, result.stderr);
  assert.match(
    result.stdout,
    /No Lighthouse baseline found for target branch master/,
  );
  const requests = await calls(state);
  assert.equal(requests.length, 1);
  assert.ok(
    requests[0].includes(`name=${state.env.LIGHTHOUSE_TARGET_ARTIFACT_NAME}`),
  );
  assert.ok(requests[0].at(-1).includes("select(.expired == false)"));
  assert.ok(requests[0].at(-1).includes("sort_by(.created_at) | last"));
});

test("restores the selected baseline archive", async (context) => {
  const state = await fixture(context, { GH_RESPONSE: "42\n" });
  const archive = path.join(state.directory, "fixture.zip");
  const archiveBytes = Buffer.from([80, 75, 3, 4, 0, 255]);
  await writeFile(archive, archiveBytes);
  const result = run("lighthouse-restore.sh", {
    ...state,
    env: { ...state.env, ARCHIVE: archive },
  });
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(
    await readFile(path.join(state.directory, "lighthouse-target.zip")),
    archiveBytes,
  );
  assert.deepEqual((await calls(state))[1], [
    "api",
    "/repos/owner/site/actions/artifacts/42/zip",
  ]);
  assert.deepEqual((await calls(state))[2], [
    "unzip",
    "-q",
    path.join(state.directory, "lighthouse-target.zip"),
    "-d",
    ".lighthouse-target",
  ]);
});

test("cleanup preserves the newly uploaded artifact", async (context) => {
  const state = await fixture(context, { GH_RESPONSE: "10\n20\n30\n" });
  const result = run("lighthouse-cleanup.sh", state);
  assert.equal(result.status, 0, result.stderr);
  const requests = await calls(state);
  assert.ok(requests[0].includes(`name=${state.env.LIGHTHOUSE_ARTIFACT_NAME}`));
  assert.deepEqual(requests.slice(1), [
    ["api", "--method", "DELETE", "/repos/owner/site/actions/artifacts/10"],
    ["api", "--method", "DELETE", "/repos/owner/site/actions/artifacts/30"],
  ]);
});

test("cleanup allows an empty artifact list", async (context) => {
  const state = await fixture(context);
  assert.equal(run("lighthouse-cleanup.sh", state).status, 0);
  assert.equal((await calls(state)).length, 1);
});

for (const script of [
  "lighthouse-environment.sh",
  "lighthouse-restore.sh",
  "lighthouse-cleanup.sh",
]) {
  test(`${script} propagates GitHub API failures`, async (context) => {
    const state = await fixture(context, { GH_FAIL: "1" });
    assert.equal(run(script, state).status, 1);
    assert.equal((await calls(state)).length, 1);
  });
}
