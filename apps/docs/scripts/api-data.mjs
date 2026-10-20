import { readdirSync } from "node:fs";
import path from "node:path";
import docsVersion from "../docs-version.json" with { type: "json" };

export function latestApiVersion(major, versions) {
  const candidates = versions
    .filter((version) => /^v[0-9]+\.[0-9]+\.[0-9]+$/.test(version))
    .map((version) => {
      const [versionMajor, minor, patch] = version.split(".");
      return {
        version,
        major: versionMajor,
        minor: Number(minor),
        patch: Number(patch),
      };
    })
    .filter((version) => version.major === major)
    .sort((a, b) => b.minor - a.minor || b.patch - a.patch);

  if (candidates.length === 0) {
    throw new Error(`No published API data for ${major}`);
  }
  return candidates[0].version;
}

export function apiDataDirectory({
  directory = "../../data/api",
  major = docsVersion.current,
} = {}) {
  return path.join(directory, latestApiVersion(major, readdirSync(directory)));
}
