import { readFile, readdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";

const scoreDefinitions = [
  ["performance", "Performance"],
  ["accessibility", "Accessibility"],
  ["bestPractices", "Best practices"],
  ["seo", "SEO"],
];

const reportCategoryKeys = {
  performance: "performance",
  accessibility: "accessibility",
  bestPractices: "best-practices",
  seo: "seo",
};

function getFiniteNumber(value, description) {
  if (!Number.isFinite(value)) {
    throw new Error(`Lighthouse report is missing ${description}`);
  }

  return value;
}

export function median(values) {
  if (values.length === 0) {
    throw new Error("Cannot calculate a median without values");
  }

  const sorted = [...values].sort((left, right) => left - right);
  const middle = Math.floor(sorted.length / 2);

  return sorted.length % 2 === 0
    ? (sorted[middle - 1] + sorted[middle]) / 2
    : sorted[middle];
}

function medianScore(reports, key) {
  return Math.round(
    median(
      reports.map((report) =>
        getFiniteNumber(
          report.categories?.[reportCategoryKeys[key]]?.score,
          `${key} category score`,
        ),
      ),
    ) * 100,
  );
}

function latestFetchTime(reports) {
  const fetchTimes = reports
    .map((report) => report.fetchTime)
    .filter((fetchTime) => typeof fetchTime === "string")
    .sort();

  if (fetchTimes.length !== reports.length) {
    throw new Error("Lighthouse report is missing its fetch time");
  }

  return fetchTimes.at(-1);
}

export function createBaseline({ reports, branch, commit, url }) {
  if (reports.length === 0) {
    throw new Error("No Lighthouse reports were found");
  }

  return {
    schemaVersion: 1,
    branch,
    commit,
    url,
    collectedAt: latestFetchTime(reports),
    runs: reports.length,
    scores: Object.fromEntries(
      scoreDefinitions.map(([key]) => [key, medianScore(reports, key)]),
    ),
  };
}

function formatDelta(target, current) {
  const delta = current - target;
  return delta > 0 ? `+${delta}` : String(delta);
}

function shortCommit(commit) {
  return commit.slice(0, 7);
}

export function formatComment({ current, target, targetBranch, artifactUrl }) {
  const comparison = target
    ? `Compared with target branch \`${target.branch}\` at commit \`${shortCommit(target.commit)}\`.`
    : `No Lighthouse baseline is available for target branch \`${targetBranch}\`.`;
  const scoreRows = scoreDefinitions.map(([key, label]) => {
    const targetScore = target?.scores[key];
    return `| ${label} | ${targetScore ?? "N/A"} | **${current.scores[key]}** | ${
      targetScore === undefined
        ? "N/A"
        : formatDelta(targetScore, current.scores[key])
    } |`;
  });

  return [
    "## Lighthouse baseline",
    "",
    `${comparison} Scores are the median of ${current.runs} runs against the deployed Cloudflare preview.`,
    "",
    "| Category | Target | Current | Change |",
    "| --- | ---: | ---: | ---: |",
    ...scoreRows,
    "",
    `[Download the full Lighthouse reports and baseline](${artifactUrl})`,
    "",
    `<sub>Commit \`${shortCommit(current.commit)}\` · [Cloudflare preview](${current.url})</sub>`,
    "",
  ].join("\n");
}

async function readReports(reportDirectory) {
  const names = (await readdir(reportDirectory))
    .filter((name) => /^lhr-.*\.json$/.test(name))
    .sort();

  return Promise.all(
    names.map(async (name) =>
      JSON.parse(await readFile(path.join(reportDirectory, name), "utf8")),
    ),
  );
}

async function readOptionalJson(filePath) {
  try {
    return JSON.parse(await readFile(filePath, "utf8"));
  } catch (error) {
    if (error?.code === "ENOENT") {
      return undefined;
    }

    throw error;
  }
}

function requiredEnvironment(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable ${name}`);
  }

  return value;
}

async function writeBaseline() {
  const reportDirectory =
    process.env.LIGHTHOUSE_REPORT_DIRECTORY ?? ".lighthouseci";
  const baselinePath =
    process.env.LIGHTHOUSE_BASELINE_PATH ??
    path.join(reportDirectory, "baseline.json");
  const targetBaselinePath =
    process.env.LIGHTHOUSE_TARGET_BASELINE_PATH ??
    path.join(".lighthouse-target", "baseline.json");
  const targetSnapshotPath = path.join(reportDirectory, "target-baseline.json");
  const [reports, target] = await Promise.all([
    readReports(reportDirectory),
    readOptionalJson(targetBaselinePath),
  ]);
  const baseline = createBaseline({
    reports,
    branch: requiredEnvironment("LIGHTHOUSE_BRANCH"),
    commit: requiredEnvironment("GITHUB_SHA"),
    url: requiredEnvironment("LIGHTHOUSE_URL"),
  });

  await writeFile(baselinePath, `${JSON.stringify(baseline, null, 2)}\n`);
  if (target) {
    await writeFile(targetSnapshotPath, `${JSON.stringify(target, null, 2)}\n`);
  }
}

async function writeComment() {
  const reportDirectory =
    process.env.LIGHTHOUSE_REPORT_DIRECTORY ?? ".lighthouseci";
  const baselinePath =
    process.env.LIGHTHOUSE_BASELINE_PATH ??
    path.join(reportDirectory, "baseline.json");
  const targetBaselinePath =
    process.env.LIGHTHOUSE_TARGET_BASELINE_PATH ??
    path.join(".lighthouse-target", "baseline.json");
  const commentPath =
    process.env.LIGHTHOUSE_COMMENT_PATH ??
    path.join(reportDirectory, "comment.md");
  const [current, target] = await Promise.all([
    readOptionalJson(baselinePath),
    readOptionalJson(targetBaselinePath),
  ]);

  if (!current) {
    throw new Error(`Current Lighthouse baseline not found at ${baselinePath}`);
  }

  await writeFile(
    commentPath,
    formatComment({
      current,
      target,
      targetBranch: requiredEnvironment("LIGHTHOUSE_TARGET_BRANCH"),
      artifactUrl: requiredEnvironment("LIGHTHOUSE_ARTIFACT_URL"),
    }),
  );
}

async function main(command) {
  if (command === "baseline") {
    await writeBaseline();
    return;
  }

  if (command === "comment") {
    await writeComment();
    return;
  }

  throw new Error(`Unknown Lighthouse report command: ${command ?? ""}`);
}

const entryPath = process.argv[1]
  ? pathToFileURL(path.resolve(process.argv[1])).href
  : "";

if (import.meta.url === entryPath) {
  await main(process.argv[2]);
}
