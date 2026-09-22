import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { gzipSync } from "node:zlib";
import { JSDOM } from "jsdom";
import {
  profileHtmlPath,
  profileUrl,
  routeProfiles,
} from "./route-profiles.mjs";

const buildDirectory = fileURLToPath(
  new URL("../build/client/", import.meta.url),
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
  return getLocalAssetUrls(
    document,
    "img[src], source[src], video[src]",
    "src",
  ).concat(getLocalAssetUrls(document, "video[poster]", "poster"));
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

function measureMedia(document, assets) {
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
    requests: assets.requests,
    rawBytes: assets.rawBytes,
    gzipBytes: assets.gzipBytes,
    localAssets: assets.requests,
    assets: assets.assets,
  };
}

function assertMeasuredAssets(name, urls) {
  if (urls.length === 0) {
    throw new Error(`Route profile report found no local ${name} assets`);
  }
}

export async function createReport({ html, readAsset }) {
  const { document } = new JSDOM(html).window;
  const javascriptUrls = getInitialJavaScriptUrls(document);
  const cssUrls = getInitialCssUrls(document);
  const mediaUrls = getLocalMediaUrls(document);

  assertMeasuredAssets("JavaScript", javascriptUrls);
  assertMeasuredAssets("CSS", cssUrls);
  const mediaAssets = await measureAssets(mediaUrls, readAsset);

  return {
    javascript: await measureAssets(javascriptUrls, readAsset),
    css: await measureAssets(cssUrls, readAsset),
    bodyElements: document.body.querySelectorAll("*").length,
    media: measureMedia(document, mediaAssets),
  };
}

function validateProfiles(profiles) {
  const identifiers = new Set();
  for (const profile of profiles) {
    if (
      !profile ||
      typeof profile.id !== "string" ||
      profile.id === "" ||
      typeof profile.family !== "string" ||
      profile.family === "" ||
      typeof profile.path !== "string" ||
      !profile.path.startsWith("/") ||
      (profile.htmlSource !== "prerendered" && profile.htmlSource !== "runtime")
    ) {
      throw new Error(
        "Route profile inputs require an id, family, absolute path, and HTML source",
      );
    }
    if (identifiers.has(profile.id)) {
      throw new Error(`Route profile id is duplicated: ${profile.id}`);
    }
    identifiers.add(profile.id);
  }
}

function assetReferences(report) {
  return [
    ...report.javascript.assets,
    ...report.css.assets,
    ...report.media.assets,
  ].map((asset) => asset.path);
}

function ownershipFor(profile, assetPath, reports, references) {
  const owners = reports.filter((candidate) =>
    references.get(candidate.id).includes(assetPath),
  );
  const sharedWith = owners
    .filter((candidate) => candidate.id !== profile.id)
    .map((candidate) => candidate.id);
  const sharedWithRoot =
    profile.id !== "homepage" &&
    owners.some((owner) => owner.id === "homepage");
  const sharedWithLayout = owners.some(
    (owner) => owner.id !== profile.id && owner.family === profile.family,
  );

  return {
    sharedWith,
    ownership: sharedWithRoot
      ? "root-shared"
      : sharedWithLayout
        ? "layout-shared"
        : "route-owned",
  };
}

function withOwnership(profile, report, reports, references) {
  const annotate = (asset) => ({
    ...asset,
    ...ownershipFor(profile, asset.path, reports, references),
  });
  return {
    ...report,
    javascript: {
      ...report.javascript,
      assets: report.javascript.assets.map(annotate),
    },
    css: { ...report.css, assets: report.css.assets.map(annotate) },
    media: { ...report.media, assets: report.media.assets.map(annotate) },
  };
}

export async function createReports({ profiles, readPage, readAsset }) {
  validateProfiles(profiles);
  const reports = await Promise.all(
    profiles.map(async (profile) => {
      const html = await readPage(profile);
      const report = await createReport({ html, readAsset });
      const htmlBytes = Buffer.byteLength(html, "utf8");
      return {
        ...profile,
        html: {
          requests: 1,
          rawBytes: htmlBytes,
          gzipBytes: gzipSync(html, { level: 9 }).byteLength,
        },
        ...report,
      };
    }),
  );
  const references = new Map(
    reports.map((report) => [report.id, assetReferences(report)]),
  );

  return {
    schemaVersion: 1,
    profiles: reports.map((report) =>
      withOwnership(report, report, reports, references),
    ),
  };
}

export async function readRuntimeProfile({ profile, requestHandler }) {
  const response = await requestHandler({
    request: new Request(profileUrl(localOrigin, profile)),
  });

  if (!response.ok) {
    throw new Error(
      `Runtime route profile ${profile.id} returned HTTP ${response.status}`,
    );
  }

  return response.text();
}

function toAssetPath(url) {
  const relativePath = decodeURIComponent(url.pathname).replace(/^\/+/, "");
  return path.join(buildDirectory, relativePath);
}

function formatReport(report) {
  return report.profiles
    .flatMap((profile) => [
      `${profile.id} (${profile.path})`,
      `HTML: ${profile.html.rawBytes} raw bytes, ${profile.html.gzipBytes} gzip bytes`,
      `JavaScript: ${profile.javascript.requests} requests, ${profile.javascript.rawBytes} raw bytes, ${profile.javascript.gzipBytes} gzip bytes`,
      `CSS: ${profile.css.requests} requests, ${profile.css.rawBytes} raw bytes, ${profile.css.gzipBytes} gzip bytes`,
      `Media: ${profile.media.requests} requests, ${profile.media.rawBytes} raw bytes, ${profile.media.gzipBytes} gzip bytes`,
      `DOM: ${profile.bodyElements} body elements`,
      `Images: ${profile.media.images} total, ${profile.media.imagesMissingWidth} missing width, ${profile.media.imagesMissingHeight} missing height`,
      `Videos: ${profile.media.videos} total, ${profile.media.videosMissingWidth} missing width, ${profile.media.videosMissingHeight} missing height`,
      "",
    ])
    .join("\n");
}

async function main() {
  const readPage = async (profile) => {
    if (profile.htmlSource === "runtime") {
      const { onRequest } = await import("../functions/try.js");
      return readRuntimeProfile({ profile, requestHandler: onRequest });
    }

    return readFile(
      path.join(buildDirectory, profileHtmlPath(profile)),
      "utf8",
    );
  };
  const report = await createReports({
    profiles: routeProfiles,
    readPage,
    readAsset: (url) => readFile(toAssetPath(url)),
  });

  console.log(
    process.argv.includes("--json")
      ? JSON.stringify(report, null, 2)
      : formatReport(report),
  );
}

const entryPath = process.argv[1]
  ? pathToFileURL(path.resolve(process.argv[1])).href
  : "";

if (import.meta.url === entryPath) {
  await main();
}
