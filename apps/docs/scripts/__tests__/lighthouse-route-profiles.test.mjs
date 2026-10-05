import assert from "node:assert/strict";
import test from "node:test";
import {
  createRouteBaseline,
  formatRouteComment,
} from "../lighthouse-report.mjs";
import { profileUrl, routeProfiles } from "../route-profiles.mjs";

const origin = "https://preview.rescript-lang.pages.dev";

function report(profile, score) {
  return {
    requestedUrl: profileUrl(origin, profile),
    fetchTime: "2026-09-21T12:00:00.000Z",
    categories: {
      performance: { score },
      accessibility: { score },
      "best-practices": { score },
      seo: { score },
    },
  };
}

test("createRouteBaseline groups deployed reports by route profile", () => {
  const baseline = createRouteBaseline({
    reports: routeProfiles.flatMap((profile) => [
      report(profile, 0.8),
      report(profile, 0.9),
    ]),
    branch: "perf/routes",
    commit: "1234567890abcdef",
    url: origin,
  });

  assert.equal(baseline.profiles.length, routeProfiles.length);
  assert.deepEqual(baseline.profiles[0], {
    id: "homepage",
    path: "/",
    url: `${origin}/`,
    runs: 2,
    scores: {
      performance: 85,
      accessibility: 85,
      bestPractices: 85,
      seo: 85,
    },
  });
});

test("createRouteBaseline rejects a missing profile report", () => {
  assert.throws(
    () =>
      createRouteBaseline({
        reports: routeProfiles.slice(1).map((profile) => report(profile, 0.8)),
        branch: "perf/routes",
        commit: "1234567890abcdef",
        url: origin,
      }),
    /homepage/,
  );
});

test("formatRouteComment records unavailable target profiles as N/A", () => {
  const current = createRouteBaseline({
    reports: routeProfiles.map((profile) => report(profile, 0.8)),
    branch: "perf/routes",
    commit: "1234567890abcdef",
    url: origin,
  });
  const comment = formatRouteComment({
    current,
    targetBranch: "master",
    artifactUrl: "https://github.com/example/artifacts/1",
  });

  assert.match(comment, /No route-profile Lighthouse baseline is available/);
  assert.match(
    comment,
    /\| `\/docs\/manual\/introduction` \| N\/A -> \*\*80\*\* \(N\/A\)/,
  );
});
