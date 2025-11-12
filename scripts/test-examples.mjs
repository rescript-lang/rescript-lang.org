import fs from "fs";
import glob from "glob";
import path from "path";
import { URL } from "url";
import child_process from "child_process";

const pathname = new URL(".", import.meta.url).pathname;
const __dirname =
  process.platform !== "win32" ? pathname : pathname.substring(1);

let tempFileName = path.join(__dirname, "../temp/src/", "_tempFile.res");
let tempFileNameRegex = /_tempFile\.res/g;

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

// TODO post RR7: revisit this
// let postprocessOutput = (file, error) => {
//   return error.stderr
//     .toString()
//     .replace(tempFileNameRegex, path.relative(".", file))
//     .replace(
//       /\/\* _MODULE_(EXAMPLE|PRELUDE|SIG)_START \*\/.+/g,
//       (_, capture) => {
//         return (
//           "```res " +
//           (capture === "EXAMPLE"
//             ? "example"
//             : capture === "PRELUDE"
//               ? "prelude"
//               : "sig")
//         );
//       },
//     )
//     .replace(/(.*)\}(.*)\/\/ _MODULE_END/g, (_, cap1, cap2) => {
//       // cap1 cap2 might be empty or ansi coloring code
//       return cap1 + "```" + cap2;
//     });
// };

console.log("Running tests...");

let rescriptJson = `{
    "name": "temp",
    "namespace": false,
    "jsx": {
      "version": 4
    },
    "dependencies": [
        "@rescript/react"
    ],
    "warnings": {
        "number": "-109-27-32"
    },
    "sources": [
        {
            "dir": "src"
        }
    ]
}`;

fs.mkdirSync(path.join(__dirname, "../temp/src/"), { recursive: true });
fs.writeFileSync(path.join(__dirname, "../temp/rescript.json"), rescriptJson);
fs.writeFileSync(tempFileName, "");

let success = true;

glob.sync(__dirname + "/../markdown-pages/docs/{manual,react}/**/*.mdx").forEach((file) => {
  let content = fs.readFileSync(file, { encoding: "utf-8" });
  let parsedResult = parseFile(content);
  if (parsedResult != null) {
    fs.writeFileSync(tempFileName, parsedResult);
    try {
      console.log("testing examples in", file);
      // -109 for suppressing `Toplevel expression is expected to have unit type.`
      // Most doc snippets do e.g. `Belt.Array.length(["test"])`, which triggers this
      child_process.execSync("npm exec rescript build ./temp -- --quiet", {
        stdio: "inherit",
      });
    } catch (e) {
      // process.stdout.write(postprocessOutput(file, e));
      success = false;
    }
  }
});

fs.unlinkSync(tempFileName);
process.exit(success ? 0 : 1);
