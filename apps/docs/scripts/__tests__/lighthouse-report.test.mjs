import assert from "node:assert/strict";
import test from "node:test";
import {
  createBaseline,
  formatComment,
  median,
} from "../lighthouse-report.mjs";

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
