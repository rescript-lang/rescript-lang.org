/*
 * This is an attempt to provide quick metrics on the build time performance
 * of BuckleScript within a Reason project.
 *
 * It requires following files in you package.json dependency list:
 * - bs-platform
 * - cloc (https://github.com/AlDanial/cloc)
 *
 * It also requires a bsconfig.json file to exist in the currently executing CWD.
 * The script will automatically pick up your bsconfig.sources configuration to find
 * all Reason file occurrences and puts it in relation to the bucklescript build times.
 *
 * This script doesn't measure "world builds" (no -clean-world / -make-world).
 *
 *
 * For Maintainers:
 * -------------------
 * No third-party libraries; only use language features available
 * to NodeJS > v12
 */

const path = require("path");
const child_process = require("child_process");
const bsconfig = require(path.join(process.cwd(), "bsconfig.json"));

const BSB_BIN = "./node_modules/.bin/bsb";

const bsbClean = () => child_process.spawnSync(BSB_BIN, ["-clean"]);

// returns time { real, user, sys }
const timeBsbBuild = () => {
  const ret = child_process.spawnSync("time", [BSB_BIN]);
  if (ret.status !== 0) {
    throw new Error(`bsb build failed with exit code ${ret.status}
fix the build issue before benchmarking
    `);
  }

  // return output of the time function
  const output = ret.stderr.toString();
  const match = output.match(/\s+(.*)\sreal\s*(.*)\suser\s*(.*)\ssys.*/);

  let time;
  if (match) {
    time = {
      real: parseFloat(match[1]),
      user: parseFloat(match[2]),
      sys: parseFloat(match[3]),
    };
  }

  return time;
};

const getFileMetrics = () => {
  const paths = bsconfig.sources.map((source) => {
    if (typeof source === "string") {
      return source;
    }
    if (typeof source === "object") {
      return source.dir;
    }
  });

  const args = paths.concat(["--include-lang=ReasonML", "--json"]);
  const ret = child_process.spawnSync("cloc", args);

  if (ret.status !== 0) {
    throw new Error(`cloc failed with exit code ${ret.status}`);
  }

  const out = JSON.parse(ret.stdout.toString());
  return {
    numberOfFiles: out.ReasonML.nFiles,
    blankLines: out.ReasonML.blank,
    commentLines: out.ReasonML.comment,
    codeLines: out.ReasonML.code,
    totalLines: out.header.n_lines,
  };
};

function main() {
  const arg = process.argv[2];
  if (arg === "--help" || arg === "-h") {
    console.log("Runs simple benchmarks for a BuckleScript project");
    return;
  }

  let asJson = true;

  console.error("Capturing LOC / file numbers...");
  const fileMetrics = getFileMetrics();

  console.error("Cleaning the project first...");
  bsbClean();

  console.error("Measuring build performance...");
  let buildTime = timeBsbBuild();

  let locPerSec = Math.round(fileMetrics.totalLines / buildTime.real);

  let result = {
    fileMetrics,
    buildTime,
    results: {
      locPerSec,
    },
  };

  if (asJson) {
    console.log(JSON.stringify(result, null, 2));
  }

  // TODO: maybe add human readable format as an option?
}

try {
  main();
} catch (err) {
  console.error("Something went wrong: " + err);
  process.exit(1);
}
