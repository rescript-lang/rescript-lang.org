import * as path from "node:path";
import * as fs from "node:fs";

import nextConfig from "../next.config.mjs";

const redirectsConfig = await nextConfig.redirects();

/**
 * @param {{
 *   source: string,
 *   destination: string,
 *   permanent: boolean,
 * }} config
 * @return {string}
 */
function lineFormat({ source, destination, permanent }) {
  return `${source}  ${destination}  ${permanent ? 308 : 307}`;
}

const redirects = redirectsConfig.map(lineFormat).join("\n");
const redirectsFile = path.join(import.meta.dirname, "../public/_redirects");
