import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { gzipSync } from "node:zlib";
import { JSDOM } from "jsdom";

const buildDirectory = fileURLToPath(
  new URL("../build/client/", import.meta.url),
);
const homepagePath = path.join(buildDirectory, "index.html");
const budgetPath = fileURLToPath(
  new URL("./homepage-performance-budget.json", import.meta.url),
);
const localOrigin = "https://build.local";

function unique(values) {
  return [...new Set(values)].sort();
}

function getLocalAssetUrls(document, selector, attribute) {
  const hrefs = [...document.querySelectorAll(selector)]
    .map((element) => element.getAttribute(attribute))
    .filter((value) => value !== null)
    .map((value) => new URL(value, localOrigin))
    .filter((url) => url.origin === localOrigin)
    .map((url) => url.href);

  return unique(hrefs).map((href) => new URL(href));
}

function getInitialJavaScriptUrls(document) {
  return getLocalAssetUrls(
    document,
    'link[rel~="modulepreload"][href], link[rel~="preload"][as="script"][href]',
    "href",
  ).concat(getLocalAssetUrls(document, "script[src]", "src"));
}

function getInitialCssUrls(document) {
  return getLocalAssetUrls(
    document,
    'link[rel~="stylesheet"][href], link[rel~="preload"][as="style"][href]',
    "href",
  );
}

function getLocalMediaUrls(document) {
  return getLocalAssetUrls(document, "img[src], source[src]", "src").concat(
    getLocalAssetUrls(document, "video[poster]", "poster"),
  );
}

async function readRequiredAsset(readAsset, url) {
  try {
    return await readAsset(url);
  } catch (cause) {
    throw new Error(`Unable to read local asset ${url.pathname}`, { cause });
  }
}

async function measureAssets(urls, readAsset) {
  const hrefs = unique(urls.map((url) => url.href));
  const assets = await Promise.all(
    hrefs.map(async (href) => {
      const url = new URL(href);
      const contents = await readRequiredAsset(readAsset, url);
      return {
        path: url.pathname,
        rawBytes: contents.byteLength,
        gzipBytes: gzipSync(contents, { level: 9 }).byteLength,
      };
    }),
  );

  return {
    requests: assets.length,
    rawBytes: assets.reduce((total, asset) => total + asset.rawBytes, 0),
    gzipBytes: assets.reduce((total, asset) => total + asset.gzipBytes, 0),
    assets,
  };
}

function hasPositiveNumericAttribute(element, attribute) {
  const value = element.getAttribute(attribute);
  return value !== null && Number.isFinite(Number(value)) && Number(value) > 0;
}

function measureMedia(document, localAssets) {
  const images = [...document.querySelectorAll("img")];
  const videos = [...document.querySelectorAll("video")];
  const countMissing = (elements, attribute) =>
    elements.filter(
      (element) => !hasPositiveNumericAttribute(element, attribute),
    ).length;

  return {
    images: images.length,
    imagesMissingWidth: countMissing(images, "width"),
    imagesMissingHeight: countMissing(images, "height"),
    videos: videos.length,
    videosMissingWidth: countMissing(videos, "width"),
    videosMissingHeight: countMissing(videos, "height"),
    localAssets,
  };
}

function assertMeasuredAssets(name, urls) {
  if (urls.length === 0) {
    throw new Error(`Homepage report found no local ${name} assets`);
  }
}

export async function createReport({ html, readAsset }) {
  const { document } = new JSDOM(html).window;
  const javascriptUrls = getInitialJavaScriptUrls(document);
  const cssUrls = getInitialCssUrls(document);
  const mediaUrls = getLocalMediaUrls(document);

  assertMeasuredAssets("JavaScript", javascriptUrls);
  assertMeasuredAssets("CSS", cssUrls);
  await Promise.all(
    unique(mediaUrls.map((url) => url.href)).map((href) =>
      readRequiredAsset(readAsset, new URL(href)),
    ),
  );

  return {
    javascript: await measureAssets(javascriptUrls, readAsset),
    css: await measureAssets(cssUrls, readAsset),
    bodyElements: document.body.querySelectorAll("*").length,
    media: measureMedia(
      document,
      unique(mediaUrls.map((url) => url.href)).length,
    ),
  };
}

export function getBudgetFailures(report, budget) {
  const checks = [
    [
      "initial JavaScript requests",
      report.javascript.requests,
      budget.javascript.requests,
    ],
    [
      "initial JavaScript raw bytes",
      report.javascript.rawBytes,
      budget.javascript.rawBytes,
    ],
    [
      "initial JavaScript gzip bytes",
      report.javascript.gzipBytes,
      budget.javascript.gzipBytes,
    ],
    ["initial CSS requests", report.css.requests, budget.css.requests],
    ["initial CSS raw bytes", report.css.rawBytes, budget.css.rawBytes],
    ["initial CSS gzip bytes", report.css.gzipBytes, budget.css.gzipBytes],
    ["body elements", report.bodyElements, budget.bodyElements],
    ["images", report.media.images, budget.media.images],
    [
      "images missing width",
      report.media.imagesMissingWidth,
      budget.media.imagesMissingWidth,
    ],
    [
      "images missing height",
      report.media.imagesMissingHeight,
      budget.media.imagesMissingHeight,
    ],
    ["videos", report.media.videos, budget.media.videos],
    [
      "videos missing width",
      report.media.videosMissingWidth,
      budget.media.videosMissingWidth,
    ],
    [
      "videos missing height",
      report.media.videosMissingHeight,
      budget.media.videosMissingHeight,
    ],
  ];

  return checks
    .filter(([, actual, maximum]) => actual > maximum)
    .map(([name, actual, maximum]) => `${name}: ${actual} exceeds ${maximum}`);
}

function toAssetPath(url) {
  const relativePath = decodeURIComponent(url.pathname).replace(/^\/+/, "");
  return path.join(buildDirectory, relativePath);
}

function formatReport(report) {
  return [
    "Homepage performance report",
    `JavaScript: ${report.javascript.requests} requests, ${report.javascript.rawBytes} raw bytes, ${report.javascript.gzipBytes} gzip bytes`,
    `CSS: ${report.css.requests} requests, ${report.css.rawBytes} raw bytes, ${report.css.gzipBytes} gzip bytes`,
    `DOM: ${report.bodyElements} body elements`,
    `Images: ${report.media.images} total, ${report.media.imagesMissingWidth} missing width, ${report.media.imagesMissingHeight} missing height`,
    `Videos: ${report.media.videos} total, ${report.media.videosMissingWidth} missing width, ${report.media.videosMissingHeight} missing height`,
    `Local media assets checked: ${report.media.localAssets}`,
  ].join("\n");
}

async function main() {
  const [html, budgetContents] = await Promise.all([
    readFile(homepagePath, "utf8"),
    readFile(budgetPath, "utf8"),
  ]);
  const report = await createReport({
    html,
    readAsset: (url) => readFile(toAssetPath(url)),
  });
  const budget = JSON.parse(budgetContents);

  console.log(
    process.argv.includes("--json")
      ? JSON.stringify(report, null, 2)
      : formatReport(report),
  );

  const failures = getBudgetFailures(report, budget);
  if (failures.length > 0) {
    throw new Error(
      `Homepage performance budgets failed:\n${failures.join("\n")}`,
    );
  }
}

const entryPath = process.argv[1]
  ? pathToFileURL(path.resolve(process.argv[1])).href
  : "";

if (import.meta.url === entryPath) {
  await main();
}
