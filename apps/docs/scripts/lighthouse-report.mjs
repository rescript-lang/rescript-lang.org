import { createHash } from "node:crypto";
import { readFile, readdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { profileUrl, routeProfiles } from "./route-profiles.mjs";

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

export function lighthouseArtifactName(branch) {
  const slug = branch
    .toLowerCase()
    .replace(/[^a-z0-9-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-+/g, "-")
    .slice(0, 80);
  const digest = createHash("sha256").update(branch, "utf8").digest("hex");

  return `homepage-lighthouse-${slug || "branch"}-${digest}`;
}

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

function normalizedPath(url) {
  const pathname = new URL(url).pathname.replace(/\/+$/, "");
  return pathname === "" ? "/" : pathname;
}

function reportsForProfile(reports, profile) {
  return reports.filter((report) => {
    const url = report.requestedUrl ?? report.finalUrl;
    return typeof url === "string" && normalizedPath(url) === profile.path;
  });
}

function hasRouteUrls(reports) {
  return reports.every(
    (report) =>
      typeof report.requestedUrl === "string" ||
      typeof report.finalUrl === "string",
  );
}

export function createRouteBaseline({ reports, branch, commit, url }) {
  return {
    schemaVersion: 1,
    branch,
    commit,
    collectedAt: latestFetchTime(reports),
    profiles: routeProfiles.map((profile) => {
      const profileReports = reportsForProfile(reports, profile);
      if (profileReports.length === 0) {
        throw new Error(
          `No Lighthouse reports were found for route profile ${profile.id}`,
        );
      }
      return {
        id: profile.id,
        path: profile.path,
        url: profileUrl(url, profile),
        runs: profileReports.length,
        scores: Object.fromEntries(
          scoreDefinitions.map(([key]) => [
            key,
            medianScore(profileReports, key),
          ]),
        ),
      };
    }),
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

function scoreComparison(current, target, key) {
  const targetScore = target?.scores[key];
  return targetScore === undefined
    ? `N/A -> **${current.scores[key]}** (N/A)`
    : `${targetScore} -> **${current.scores[key]}** (${formatDelta(targetScore, current.scores[key])})`;
}

export function formatRouteComment({
  current,
  target,
  targetBranch,
  artifactUrl,
}) {
  const comparison = target
    ? `Compared with target branch \`${target.branch}\` at commit \`${shortCommit(target.commit)}\`.`
    : `No route-profile Lighthouse baseline is available for target branch \`${targetBranch}\`.`;
  const targetProfiles = new Map(
    (target?.profiles ?? []).map((profile) => [profile.id, profile]),
  );
  const profileRows = current.profiles.map((profile) => {
    const targetProfile = targetProfiles.get(profile.id);
    return `| \`${profile.path}\` | ${scoreComparison(profile, targetProfile, "performance")} | ${scoreComparison(profile, targetProfile, "accessibility")} | ${scoreComparison(profile, targetProfile, "bestPractices")} | ${scoreComparison(profile, targetProfile, "seo")} |`;
  });

  return [
    "## Lighthouse route profiles",
    "",
    `${comparison} Every score is the median of the deployed preview runs for that route.`,
    "",
    "| Route | Performance | Accessibility | Best practices | SEO |",
    "| --- | --- | --- | --- | --- |",
    ...profileRows,
    "",
    `[Download the full Lighthouse reports and baselines](${artifactUrl})`,
    "",
    `<sub>Commit \`${shortCommit(current.commit)}\`</sub>`,
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
  const routeBaselinePath = path.join(reportDirectory, "route-profiles.json");
  const targetRouteBaselinePath = path.join(
    ".lighthouse-target",
    "route-profiles.json",
  );
  const targetRouteSnapshotPath = path.join(
    reportDirectory,
    "target-route-profiles.json",
  );
  const [reports, target, targetRoutes] = await Promise.all([
    readReports(reportDirectory),
    readOptionalJson(targetBaselinePath),
    readOptionalJson(targetRouteBaselinePath),
  ]);
  const baseline = createBaseline({
    reports,
    branch: requiredEnvironment("LIGHTHOUSE_BRANCH"),
    commit: requiredEnvironment("GITHUB_SHA"),
    url: requiredEnvironment("LIGHTHOUSE_URL"),
  });
  const routeBaseline = hasRouteUrls(reports)
    ? createRouteBaseline({
        reports,
        branch: requiredEnvironment("LIGHTHOUSE_BRANCH"),
        commit: requiredEnvironment("GITHUB_SHA"),
        url: requiredEnvironment("LIGHTHOUSE_URL"),
      })
    : undefined;

  await writeFile(baselinePath, `${JSON.stringify(baseline, null, 2)}\n`);
  if (routeBaseline) {
    await writeFile(
      routeBaselinePath,
      `${JSON.stringify(routeBaseline, null, 2)}\n`,
    );
  }
  if (target) {
    await writeFile(targetSnapshotPath, `${JSON.stringify(target, null, 2)}\n`);
  }
  if (targetRoutes) {
    await writeFile(
      targetRouteSnapshotPath,
      `${JSON.stringify(targetRoutes, null, 2)}\n`,
    );
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
  const routeBaselinePath = path.join(reportDirectory, "route-profiles.json");
  const targetRouteBaselinePath = path.join(
    ".lighthouse-target",
    "route-profiles.json",
  );
  const [current, target, currentRoutes, targetRoutes] = await Promise.all([
    readOptionalJson(baselinePath),
    readOptionalJson(targetBaselinePath),
    readOptionalJson(routeBaselinePath),
    readOptionalJson(targetRouteBaselinePath),
  ]);

  if (!current) {
    throw new Error(`Current Lighthouse baseline not found at ${baselinePath}`);
  }

  await writeFile(
    commentPath,
    currentRoutes
      ? formatRouteComment({
          current: currentRoutes,
          target: targetRoutes,
          targetBranch: requiredEnvironment("LIGHTHOUSE_TARGET_BRANCH"),
          artifactUrl: requiredEnvironment("LIGHTHOUSE_ARTIFACT_URL"),
        })
      : formatComment({
          current,
          target,
          targetBranch: requiredEnvironment("LIGHTHOUSE_TARGET_BRANCH"),
          artifactUrl: requiredEnvironment("LIGHTHOUSE_ARTIFACT_URL"),
        }),
  );
}

async function main(command, branch) {
  if (command === "artifact-name") {
    if (!branch) {
      throw new Error("A branch name is required for artifact-name");
    }

    console.log(lighthouseArtifactName(branch));
    return;
  }

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
  await main(process.argv[2], process.argv[3]);
}
