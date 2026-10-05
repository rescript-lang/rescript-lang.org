import assert from "node:assert/strict";
import test from "node:test";
import { createReports, readRuntimeProfile } from "../homepage-performance.mjs";
import { routeProfiles } from "../route-profiles.mjs";

const assets = {
  "/assets/root.js": Buffer.from("root"),
  "/assets/docs.js": Buffer.from("docs"),
  "/assets/article.js": Buffer.from("article"),
  "/assets/site.css": Buffer.from("site"),
  "/assets/content.css": Buffer.from("content"),
  "/images/article.avif": Buffer.from("article image"),
};

const pages = {
  homepage: `<!doctype html><html><head>
    <link rel="modulepreload" href="/assets/root.js">
    <link rel="stylesheet" href="/assets/site.css">
  </head><body><main>Home</main></body></html>`,
  docs: `<!doctype html><html><head>
    <link rel="modulepreload" href="/assets/root.js">
    <link rel="modulepreload" href="/assets/docs.js">
    <link rel="stylesheet" href="/assets/site.css">
    <link rel="stylesheet" href="/assets/content.css">
  </head><body><main>Docs</main></body></html>`,
  article: `<!doctype html><html><head>
    <link rel="modulepreload" href="/assets/root.js">
    <link rel="modulepreload" href="/assets/docs.js">
    <link rel="modulepreload" href="/assets/article.js">
    <link rel="stylesheet" href="/assets/site.css">
    <link rel="stylesheet" href="/assets/content.css">
  </head><body><main><img src="/images/article.avif" width="400" height="300"></main></body></html>`,
  community: `<!doctype html><html><head>
    <link rel="modulepreload" href="/assets/root.js">
    <link rel="stylesheet" href="/assets/site.css">
    <link rel="stylesheet" href="/assets/content.css">
  </head><body><main>Community</main></body></html>`,
};

const profiles = [
  { id: "homepage", family: "homepage", path: "/", htmlSource: "prerendered" },
  {
    id: "docs-introduction",
    family: "documentation",
    path: "/docs",
    htmlSource: "prerendered",
  },
  {
    id: "docs-article",
    family: "documentation",
    path: "/docs/article",
    htmlSource: "prerendered",
  },
  {
    id: "community-overview",
    family: "community",
    path: "/community",
    htmlSource: "prerendered",
  },
];

test("the playground profile reads HTML from the runtime handler", async () => {
  const profile = routeProfiles.find(({ id }) => id === "playground");
  assert.ok(profile);
  let requestedUrl;
  const html = await readRuntimeProfile({
    profile,
    requestHandler: async ({ request }) => {
      requestedUrl = request.url;
      return new Response("<html><body>Playground</body></html>");
    },
  });

  assert.equal(profile.htmlSource, "runtime");
  assert.equal(requestedUrl, "https://build.local/try");
  assert.equal(html, "<html><body>Playground</body></html>");
});

test("the runtime profile rejects an unsuccessful response", async () => {
  const profile = routeProfiles.find(({ id }) => id === "playground");
  assert.ok(profile);

  await assert.rejects(
    readRuntimeProfile({
      profile,
      requestHandler: async () => new Response("Unavailable", { status: 503 }),
    }),
    /playground returned HTTP 503/,
  );
});

test("createReports measures every profile and exposes asset ownership", async () => {
  const report = await createReports({
    profiles,
    readPage: async (profile) =>
      pages[
        profile.id === "homepage"
          ? "homepage"
          : profile.id === "docs-introduction"
            ? "docs"
            : profile.id === "docs-article"
              ? "article"
              : "community"
      ],
    readAsset: async (url) => assets[url.pathname],
  });

  assert.equal(report.schemaVersion, 1);
  assert.equal(report.profiles.length, 4);
  const docs = report.profiles[1];
  const article = report.profiles[2];
  assert.equal(docs.html.requests, 1);
  assert.equal(docs.html.rawBytes > 0, true);
  assert.equal(article.media.requests, 1);
  assert.deepEqual(docs.javascript.assets, [
    {
      path: "/assets/docs.js",
      rawBytes: 4,
      gzipBytes: docs.javascript.assets[0].gzipBytes,
      sharedWith: ["docs-article"],
      ownership: "layout-shared",
    },
    {
      path: "/assets/root.js",
      rawBytes: 4,
      gzipBytes: docs.javascript.assets[1].gzipBytes,
      sharedWith: ["homepage", "docs-article", "community-overview"],
      ownership: "root-shared",
    },
  ]);
  assert.deepEqual(
    docs.css.assets.find(({ path }) => path === "/assets/content.css"),
    {
      path: "/assets/content.css",
      rawBytes: 7,
      gzipBytes: docs.css.assets[0].gzipBytes,
      sharedWith: ["docs-article", "community-overview"],
      ownership: "layout-shared",
    },
  );
  assert.equal(article.media.assets[0].ownership, "route-owned");
});

test("createReports rejects malformed and duplicate profile inputs", async () => {
  await assert.rejects(
    createReports({
      profiles: [
        {
          id: "duplicate",
          family: "control",
          path: "not-absolute",
          htmlSource: "prerendered",
        },
      ],
      readPage: async () => pages.homepage,
      readAsset: async (url) => assets[url.pathname],
    }),
    /absolute path/,
  );
  await assert.rejects(
    createReports({
      profiles: [
        {
          id: "invalid-source",
          family: "control",
          path: "/invalid-source",
          htmlSource: "unknown",
        },
      ],
      readPage: async () => pages.homepage,
      readAsset: async (url) => assets[url.pathname],
    }),
    /HTML source/,
  );
  await assert.rejects(
    createReports({
      profiles: [
        {
          id: "duplicate",
          family: "control",
          path: "/one",
          htmlSource: "prerendered",
        },
        {
          id: "duplicate",
          family: "control",
          path: "/two",
          htmlSource: "prerendered",
        },
      ],
      readPage: async () => pages.homepage,
      readAsset: async (url) => assets[url.pathname],
    }),
    /duplicated/,
  );
});
