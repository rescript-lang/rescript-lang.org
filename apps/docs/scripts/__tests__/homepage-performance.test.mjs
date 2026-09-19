import assert from "node:assert/strict";
import test from "node:test";
import { gzipSync } from "node:zlib";
import { createReport, getBudgetFailures } from "../homepage-performance.mjs";

const javascript = Buffer.from("console.log('home')");
const css = Buffer.from("body { color: black; }");
const image = Buffer.from("image");
const poster = Buffer.from("poster");

const assets = new Map([
  ["/assets/home.js", javascript],
  ["/assets/home.css", css],
  ["/images/home.png", image],
  ["/images/poster.png", poster],
]);

const html = `<!doctype html>
<html>
  <head>
    <link rel="modulepreload prefetch" href="/assets/home.js">
    <link rel="stylesheet" href="/assets/home.css">
    <link rel="preload" as="style" href="/assets/home.css">
    <link rel="stylesheet" href="https://fonts.example/font.css">
  </head>
  <body>
    <main><img src="/images/home.png"></main>
    <video poster="/images/poster.png"></video>
  </body>
</html>`;

function readAsset(url) {
  const contents = assets.get(url.pathname);
  if (contents === undefined) {
    throw new Error(`missing fixture ${url.pathname}`);
  }
  return contents;
}

test("createReport measures unique local assets and media contracts", async () => {
  const report = await createReport({ html, readAsset });

  assert.deepEqual(report.javascript, {
    requests: 1,
    rawBytes: javascript.byteLength,
    gzipBytes: gzipSync(javascript, { level: 9 }).byteLength,
    assets: [
      {
        path: "/assets/home.js",
        rawBytes: javascript.byteLength,
        gzipBytes: gzipSync(javascript, { level: 9 }).byteLength,
      },
    ],
  });
  assert.equal(report.css.requests, 1);
  assert.equal(report.css.rawBytes, css.byteLength);
  assert.equal(report.bodyElements, 3);
  assert.deepEqual(report.media, {
    images: 1,
    imagesMissingWidth: 1,
    imagesMissingHeight: 1,
    videos: 1,
    videosMissingWidth: 1,
    videosMissingHeight: 1,
    localAssets: 2,
  });
});

test("createReport rejects a missing local media asset", async () => {
  await assert.rejects(
    createReport({
      html: html.replace("/images/home.png", "/images/missing.png"),
      readAsset,
    }),
    /Unable to read local asset \/images\/missing.png/,
  );
});

test("createReport rejects an empty initial asset group", async () => {
  await assert.rejects(
    createReport({
      html: "<!doctype html><html><body><main>Home</main></body></html>",
      readAsset,
    }),
    /found no local JavaScript assets/,
  );
});

test("getBudgetFailures reports each exceeded ceiling", () => {
  const report = {
    javascript: { requests: 2, rawBytes: 20, gzipBytes: 10 },
    css: { requests: 1, rawBytes: 10, gzipBytes: 5 },
    bodyElements: 4,
    media: {
      images: 1,
      imagesMissingWidth: 1,
      imagesMissingHeight: 1,
      videos: 0,
      videosMissingWidth: 0,
      videosMissingHeight: 0,
    },
  };
  const budget = {
    javascript: { requests: 1, rawBytes: 19, gzipBytes: 9 },
    css: { requests: 1, rawBytes: 10, gzipBytes: 5 },
    bodyElements: 3,
    media: {
      images: 1,
      imagesMissingWidth: 0,
      imagesMissingHeight: 0,
      videos: 0,
      videosMissingWidth: 0,
      videosMissingHeight: 0,
    },
  };

  assert.deepEqual(getBudgetFailures(report, budget), [
    "initial JavaScript requests: 2 exceeds 1",
    "initial JavaScript raw bytes: 20 exceeds 19",
    "initial JavaScript gzip bytes: 10 exceeds 9",
    "body elements: 4 exceeds 3",
    "images missing width: 1 exceeds 0",
    "images missing height: 1 exceeds 0",
  ]);
});
