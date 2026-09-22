import assert from "node:assert/strict";
import test from "node:test";
import { createReports } from "../homepage-performance.mjs";

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
};

const profiles = [
  { id: "homepage", family: "homepage", path: "/" },
  { id: "docs-introduction", family: "documentation", path: "/docs" },
  { id: "docs-article", family: "documentation", path: "/docs/article" },
];

test("createReports measures every profile and exposes asset ownership", async () => {
  const report = await createReports({
    profiles,
    readPage: async (profile) =>
      pages[
        profile.id === "homepage"
          ? "homepage"
          : profile.id === "docs-introduction"
            ? "docs"
            : "article"
      ],
    readAsset: async (url) => assets[url.pathname],
  });

  assert.equal(report.schemaVersion, 1);
  assert.equal(report.profiles.length, 3);
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
      sharedWith: ["homepage", "docs-article"],
      ownership: "root-shared",
    },
  ]);
  assert.equal(article.media.assets[0].ownership, "route-owned");
});

test("createReports rejects malformed and duplicate profile inputs", async () => {
  await assert.rejects(
    createReports({
      profiles: [{ id: "duplicate", family: "control", path: "not-absolute" }],
      readPage: async () => pages.homepage,
      readAsset: async (url) => assets[url.pathname],
    }),
    /absolute path/,
  );
  await assert.rejects(
    createReports({
      profiles: [
        { id: "duplicate", family: "control", path: "/one" },
        { id: "duplicate", family: "control", path: "/two" },
      ],
      readPage: async () => pages.homepage,
      readAsset: async (url) => assets[url.pathname],
    }),
    /duplicated/,
  );
});
