import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  createBaseline,
  formatComment,
  lighthouseArtifactName,
  median,
} from "../lighthouse-report.mjs";

test("Lighthouse artifact names preserve a readable prefix and stable digest", () => {
  assert.equal(
    lighthouseArtifactName("perf/fonts"),
    "homepage-lighthouse-perf-fonts-a9ef7a117bc3c939559f13724bd78bbc231b97b13463faf0ef79c93832877844",
  );
});

const collidingBranches = [
  { description: "slash and hyphen", branches: ["perf/fonts", "perf-fonts"] },
  { description: "case", branches: ["perf/fonts", "Perf/Fonts"] },
  {
    description: "truncated suffixes",
    branches: [`${"a".repeat(80)}-one`, `${"a".repeat(80)}-two`],
  },
  { description: "Unicode", branches: ["\u65e5\u672c", "\u4e2d\u6587"] },
];

for (const { description, branches } of collidingBranches) {
  test(`Lighthouse artifact names distinguish ${description}`, () => {
    const names = branches.map(lighthouseArtifactName);

    assert.equal(new Set(names).size, branches.length);
    for (const name of names) {
      assert.match(name, /^homepage-lighthouse-[a-z0-9-]{1,80}-[a-f0-9]{64}$/);
    }
  });
}

const reportScript = fileURLToPath(
  new URL("../lighthouse-report.mjs", import.meta.url),
);

test("artifact-name CLI prints the same key used by the report helper", () => {
  const result = spawnSync(
    process.execPath,
    [reportScript, "artifact-name", "perf/fonts"],
    { encoding: "utf8" },
  );

  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, `${lighthouseArtifactName("perf/fonts")}\n`);
});

test("artifact-name CLI rejects missing and empty branch names", () => {
  for (const arguments_ of [[], [""]]) {
    const result = spawnSync(
      process.execPath,
      [reportScript, "artifact-name", ...arguments_],
      { encoding: "utf8" },
    );

    assert.equal(result.status, 1);
    assert.equal(result.stdout, "");
    assert.match(result.stderr, /A branch name is required for artifact-name/);
  }
});

function report({ performance, accessibility, bestPractices, seo, fetchTime }) {
  return {
    fetchTime,
    categories: {
      performance: { score: performance },
      accessibility: { score: accessibility },
      "best-practices": { score: bestPractices },
      seo: { score: seo },
    },
  };
}

const reports = [
  report({
    performance: 0.79,
    accessibility: 0.73,
    bestPractices: 1,
    seo: 0.5,
    fetchTime: "2026-09-18T13:01:00.000Z",
  }),
  report({
    performance: 0.88,
    accessibility: 0.74,
    bestPractices: 0.96,
    seo: 0.51,
    fetchTime: "2026-09-18T13:02:00.000Z",
  }),
  report({
    performance: 0.8,
    accessibility: 0.72,
    bestPractices: 0.98,
    seo: 0.49,
    fetchTime: "2026-09-18T13:03:00.000Z",
  }),
];

test("median handles odd and even collections without changing the input", () => {
  const values = [3, 1, 2];

  assert.equal(median(values), 2);
  assert.equal(median([4, 1, 3, 2]), 2.5);
  assert.deepEqual(values, [3, 1, 2]);
});

test("createBaseline records median Lighthouse scores", () => {
  assert.deepEqual(
    createBaseline({
      reports,
      branch: "perf/homepage",
      commit: "1234567890abcdef",
      url: "https://1234.rescript-lang.pages.dev",
    }),
    {
      schemaVersion: 1,
      branch: "perf/homepage",
      commit: "1234567890abcdef",
      url: "https://1234.rescript-lang.pages.dev",
      collectedAt: "2026-09-18T13:03:00.000Z",
      runs: 3,
      scores: {
        performance: 80,
        accessibility: 73,
        bestPractices: 98,
        seo: 50,
      },
    },
  );
});

test("formatComment compares scores and links the full artifact", () => {
  const current = createBaseline({
    reports,
    branch: "perf/homepage",
    commit: "1234567890abcdef",
    url: "https://1234.rescript-lang.pages.dev",
  });
  const target = {
    ...current,
    branch: "test/homepage-performance-guardrails",
    commit: "abcdef1234567890",
    scores: {
      performance: 78,
      accessibility: 74,
      bestPractices: 98,
      seo: 50,
    },
  };
  const comment = formatComment({
    current,
    target,
    targetBranch: "test/homepage-performance-guardrails",
    artifactUrl: "https://github.com/example/actions/runs/1/artifacts/2",
  });

  assert.match(
    comment,
    /Compared with target branch `test\/homepage-performance-guardrails` at commit `abcdef1`/,
  );
  assert.match(comment, /\| Category \| Target \| Current \| Change \|/);
  assert.match(comment, /\| Performance \| 78 \| \*\*80\*\* \| \+2 \|/);
  assert.match(comment, /\| Accessibility \| 74 \| \*\*73\*\* \| -1 \|/);
  assert.match(
    comment,
    /\[Download the full Lighthouse reports and baseline\]\(https:\/\/github\.com\/example\/actions\/runs\/1\/artifacts\/2\)/,
  );
});

test("formatComment identifies a missing target branch baseline", () => {
  const current = createBaseline({
    reports,
    branch: "perf/homepage",
    commit: "1234567890abcdef",
    url: "https://1234.rescript-lang.pages.dev",
  });
  const comment = formatComment({
    current,
    target: undefined,
    targetBranch: "master",
    artifactUrl: "https://github.com/example/actions/runs/1/artifacts/2",
  });

  assert.match(
    comment,
    /No Lighthouse baseline is available for target branch `master`/,
  );
  assert.match(comment, /\| Performance \| N\/A \| \*\*80\*\* \| N\/A \|/);
});

const baselineInput = {
  reports,
  branch: "perf/homepage",
  commit: "1234567890abcdef",
  url: "https://1234.rescript-lang.pages.dev",
};

const targetBaseline = createBaseline({
  ...baselineInput,
  branch: "master",
  commit: "abcdef1234567890",
});

async function createWorkspace(context, reportDirectory = ".lighthouseci") {
  const directory = await mkdtemp(path.join(tmpdir(), "lighthouse-report-"));
  context.after(() => rm(directory, { recursive: true, force: true }));
  await mkdir(path.join(directory, reportDirectory));
  await mkdir(path.join(directory, ".lighthouse-target"));
  await Promise.all(
    reports.map((report, index) =>
      writeFile(
        path.join(directory, reportDirectory, `lhr-${index}.json`),
        JSON.stringify(report),
      ),
    ),
  );
  await writeFile(path.join(directory, reportDirectory, "manifest.json"), "{}");
  return directory;
}

function runReportCommand(directory, command, environment = {}) {
  const inheritedEnvironment = Object.fromEntries(
    Object.entries(process.env).filter(
      ([key]) => !key.startsWith("LIGHTHOUSE_") && key !== "GITHUB_SHA",
    ),
  );
  return spawnSync(process.execPath, [reportScript, ...command], {
    cwd: directory,
    encoding: "utf8",
    env: {
      ...inheritedEnvironment,
      LIGHTHOUSE_BRANCH: baselineInput.branch,
      GITHUB_SHA: baselineInput.commit,
      LIGHTHOUSE_URL: baselineInput.url,
      LIGHTHOUSE_TARGET_BRANCH: "master",
      LIGHTHOUSE_ARTIFACT_URL:
        "https://github.com/example/actions/runs/1/artifacts/2",
      ...environment,
    },
  });
}

async function readJson(filePath) {
  return JSON.parse(await readFile(filePath, "utf8"));
}

test("baseline and comment CLI preserve the restored target in the report artifact", async (context) => {
  const directory = await createWorkspace(context);
  await writeFile(
    path.join(directory, ".lighthouse-target/baseline.json"),
    JSON.stringify(targetBaseline),
  );

  const baselineResult = runReportCommand(directory, ["baseline"]);
  assert.equal(baselineResult.status, 0, baselineResult.stderr);
  assert.deepEqual(
    await readJson(path.join(directory, ".lighthouseci/baseline.json")),
    createBaseline(baselineInput),
  );
  assert.deepEqual(
    await readJson(path.join(directory, ".lighthouseci/target-baseline.json")),
    targetBaseline,
  );

  const commentResult = runReportCommand(directory, ["comment"]);
  assert.equal(commentResult.status, 0, commentResult.stderr);
  const comment = await readFile(
    path.join(directory, ".lighthouseci/comment.md"),
    "utf8",
  );
  assert.match(
    comment,
    /Compared with target branch `master` at commit `abcdef1`/,
  );
  assert.match(comment, /\| Performance \| 80 \| \*\*80\*\* \| 0 \|/);
  assert.match(comment, /actions\/runs\/1\/artifacts\/2/);
});

test("baseline and comment CLI support an absent target baseline", async (context) => {
  const directory = await createWorkspace(context);
  const baselineResult = runReportCommand(directory, ["baseline"]);
  assert.equal(baselineResult.status, 0, baselineResult.stderr);
  await assert.rejects(
    readFile(path.join(directory, ".lighthouseci/target-baseline.json")),
    { code: "ENOENT" },
  );

  const commentResult = runReportCommand(directory, ["comment"]);
  assert.equal(commentResult.status, 0, commentResult.stderr);
  const comment = await readFile(
    path.join(directory, ".lighthouseci/comment.md"),
    "utf8",
  );
  assert.match(
    comment,
    /No Lighthouse baseline is available for target branch `master`/,
  );
  assert.match(comment, /\| Performance \| N\/A \| \*\*80\*\* \| N\/A \|/);
});

test("report CLI honors configured input and output paths", async (context) => {
  const directory = await createWorkspace(context, "reports");
  const environment = {
    LIGHTHOUSE_REPORT_DIRECTORY: path.join(directory, "reports"),
    LIGHTHOUSE_BASELINE_PATH: path.join(directory, "current.json"),
    LIGHTHOUSE_TARGET_BASELINE_PATH: path.join(directory, "target.json"),
    LIGHTHOUSE_COMMENT_PATH: path.join(directory, "summary.md"),
  };
  await writeFile(
    environment.LIGHTHOUSE_TARGET_BASELINE_PATH,
    JSON.stringify(targetBaseline),
  );

  const baselineResult = runReportCommand(directory, ["baseline"], environment);
  assert.equal(baselineResult.status, 0, baselineResult.stderr);
  assert.deepEqual(
    await readJson(environment.LIGHTHOUSE_BASELINE_PATH),
    createBaseline(baselineInput),
  );
  assert.deepEqual(
    await readJson(path.join(directory, "reports/target-baseline.json")),
    targetBaseline,
  );

  const commentResult = runReportCommand(directory, ["comment"], environment);
  assert.equal(commentResult.status, 0, commentResult.stderr);
  assert.match(
    await readFile(environment.LIGHTHOUSE_COMMENT_PATH, "utf8"),
    /Compared with target branch `master`/,
  );
});

test("report CLI rejects missing required environment variables", async (context) => {
  const directory = await createWorkspace(context);
  const baselineResult = runReportCommand(directory, ["baseline"]);
  assert.equal(baselineResult.status, 0, baselineResult.stderr);

  const requiredVariables = [
    ["baseline", "LIGHTHOUSE_BRANCH"],
    ["baseline", "GITHUB_SHA"],
    ["baseline", "LIGHTHOUSE_URL"],
    ["comment", "LIGHTHOUSE_TARGET_BRANCH"],
    ["comment", "LIGHTHOUSE_ARTIFACT_URL"],
  ];
  for (const [command, variable] of requiredVariables) {
    const result = runReportCommand(directory, [command], { [variable]: "" });
    assert.equal(result.status, 1);
    assert.ok(
      result.stderr.includes(
        `Missing required environment variable ${variable}`,
      ),
    );
  }
});

test("comment CLI rejects a missing current baseline", async (context) => {
  const directory = await createWorkspace(context);
  const result = runReportCommand(directory, ["comment"]);

  assert.equal(result.status, 1);
  assert.match(result.stderr, /Current Lighthouse baseline not found/);
});

test("baseline CLI rejects malformed target JSON", async (context) => {
  const directory = await createWorkspace(context);
  await writeFile(
    path.join(directory, ".lighthouse-target/baseline.json"),
    "not JSON",
  );
  const result = runReportCommand(directory, ["baseline"]);

  assert.equal(result.status, 1);
  assert.match(result.stderr, /SyntaxError/);
  await assert.rejects(
    readFile(path.join(directory, ".lighthouseci/baseline.json")),
    {
      code: "ENOENT",
    },
  );
});

test("report CLI rejects missing and unknown commands", async (context) => {
  const directory = await createWorkspace(context);
  for (const command of [[], ["unknown"]]) {
    const result = runReportCommand(directory, command);
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Unknown Lighthouse report command/);
  }
});

test("baseline rejects absent reports, missing fetch times, and invalid scores", () => {
  assert.throws(() => median([]), /Cannot calculate a median without values/);
  assert.throws(
    () => createBaseline({ ...baselineInput, reports: [] }),
    /No Lighthouse reports were found/,
  );
  assert.throws(
    () => createBaseline({ ...baselineInput, reports: [{ categories: {} }] }),
    /missing its fetch time/,
  );
  for (const categories of [undefined, {}, { performance: { score: null } }]) {
    assert.throws(
      () =>
        createBaseline({
          ...baselineInput,
          reports: [{ fetchTime: "2026-09-18T13:01:00.000Z", categories }],
        }),
      /missing performance category score/,
    );
  }
});
