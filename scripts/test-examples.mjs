import glob from "glob";
import fs from "fs";
import child_process from "child_process";
import path from "path";
import { URL } from "url";

const pathname = new URL(".", import.meta.url).pathname;
const __dirname =
  process.platform !== "win32" ? pathname : pathname.substring(1);

let tempFileName = path.join(__dirname, "..", "_tempFile.res");
let tempFileNameRegex = /_tempFile\.res/g;

// TODO: In the future we need to use the appropriate rescript version for each doc version variant
//       see the package.json on how to define another rescript version
let compilersDir = path.join(__dirname, "..", "compilers");

let bsc = path.join(
  compilersDir,
  "node_modules",
  "rescript-1110",
  process.platform,
  "bsc.exe",
);
let rescriptBin = path.join(
  compilersDir,
  "node_modules",
  "rescript-1110",
  "rescript",
);
let rescriptCoreCompiled = path.join(
  compilersDir,
  "node_modules",
  "@rescript",
  "core",
  "lib",
  "ocaml",
);
let rescriptReactCompiled = path.join(
  compilersDir,
  "node_modules",
  "@rescript",
  "react",
  "lib",
  "ocaml",
);

const prepareCompilers = () => {
  if (fs.existsSync(bsc)) {
    return;
  }
  console.log("compilers not installed. Installing compilers...");
  child_process.execFileSync("npm", ["install"], { cwd: compilersDir });
};

const prepareDependencies = () => {
  if (
    fs.existsSync(rescriptCoreCompiled) &&
    fs.existsSync(rescriptReactCompiled)
  ) {
    return;
  }
  console.log("Dependencies not installed. Installing...");
  child_process.execFileSync(rescriptBin, [], { cwd: compilersDir });
};

let parseFile = (content) => {
  if (!/```res (example|prelude|sig)/.test(content)) {
    return;
  }

  let inCodeBlock = false;
  let moduleId = 0;
  return content
    .split("\n")
    .map((line) => {
      let modifiedLine = "";
      if (line.startsWith("```res example")) {
        inCodeBlock = true;
        modifiedLine = `/* _MODULE_EXAMPLE_START */ module M_${moduleId++} = {`;
      } else if (line.startsWith("```res prelude")) {
        inCodeBlock = true;
        modifiedLine = `/* _MODULE_PRELUDE_START */ include {`;
      } else if (line.startsWith("```res sig")) {
        inCodeBlock = true;
        modifiedLine = `/* _MODULE_SIG_START */ module type M_${moduleId++} = {`;
      } else if (inCodeBlock) {
        if (line.startsWith("```")) {
          inCodeBlock = false;
          modifiedLine = "} // _MODULE_END";
        } else {
          modifiedLine = line;
        }
      }

      return modifiedLine;
    })
    .join("\n");
};

let postprocessOutput = (file, error) => {
  return error.stderr
    .toString()
    .replace(tempFileNameRegex, path.relative(".", file))
    .replace(
      /\/\* _MODULE_(EXAMPLE|PRELUDE|SIG)_START \*\/.+/g,
      (_, capture) => {
        return (
          "```res " +
          (capture === "EXAMPLE"
            ? "example"
            : capture === "PRELUDE"
              ? "prelude"
              : "sig")
        );
      },
    )
    .replace(/(.*)\}(.*)\/\/ _MODULE_END/g, (_, cap1, cap2) => {
      // cap1 cap2 might be empty or ansi coloring code
      return cap1 + "```" + cap2;
    });
};

prepareCompilers();
prepareDependencies();

console.log("Running tests...");
fs.writeFileSync(tempFileName, "");

let success = true;

glob
  .sync(__dirname + "/../pages/docs/{manual/latest,react/latest}/**/*.mdx")
  .forEach((file) => {
    let content = fs.readFileSync(file, { encoding: "utf-8" });
    let parsedResult = parseFile(content);
    if (parsedResult != null) {
      fs.writeFileSync(tempFileName, parsedResult);
      try {
        // -109 for suppressing `Toplevel expression is expected to have unit type.`
        // Most doc snippets do e.g. `Belt.Array.length(["test"])`, which triggers this
        child_process.execFileSync(
          bsc,
          [
            tempFileName,
            "-I",
            rescriptCoreCompiled,
            "-I",
            rescriptReactCompiled,
            "-bs-jsx",
            "4",
            "-w",
            "-109",
            "-uncurried",
            "-open",
            "RescriptCore",
          ],
          { stdio: "pipe" },
        );
      } catch (e) {
        process.stdout.write(postprocessOutput(file, e));
        success = false;
      }
    }
  });

fs.unlinkSync(tempFileName);
process.exit(success ? 0 : 1);
