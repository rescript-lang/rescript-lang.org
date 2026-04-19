import fs from "fs";
import { globSync } from "tinyglobby";
import path from "path";
import { fileURLToPath } from "url";
import child_process from "child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..");

const rescriptJson = `{
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
        modifiedLine = "/* _MODULE_PRELUDE_START */ include {";
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

let ensureTempProject = (tempRoot) => {
  fs.mkdirSync(path.join(tempRoot, "src"), { recursive: true });
  fs.writeFileSync(path.join(tempRoot, "rescript.json"), rescriptJson);
  fs.writeFileSync(path.join(tempRoot, "src", "_tempFile.res"), "");
  let tempNodeModules = path.join(tempRoot, "node_modules", "@rescript");
  let tempReactPackage = path.join(tempNodeModules, "react");
  if (!fs.existsSync(tempReactPackage)) {
    fs.mkdirSync(tempNodeModules, { recursive: true });
    fs.cpSync(
      path.join(projectRoot, "node_modules", "@rescript", "react"),
      tempReactPackage,
      { recursive: true },
    );
  }
};

export let run = ({
  docsRoot = path.join(projectRoot, "markdown-pages", "docs"),
  tempRoot = path.join(projectRoot, "temp"),
  logger = console,
} = {}) => {
  logger.log("Running tests...");
  ensureTempProject(tempRoot);

  let success = true;

  globSync("{manual,react}/**/*.mdx", {
    cwd: docsRoot,
    absolute: true,
  }).forEach((file) => {
    let content = fs.readFileSync(file, { encoding: "utf-8" });
    let parsedResult = parseFile(content);
    if (parsedResult == null) {
      return;
    }

    fs.writeFileSync(path.join(tempRoot, "src", "_tempFile.res"), parsedResult);
    try {
      logger.log("testing examples in", file);
      child_process.execFileSync(
        "npm",
        ["exec", "rescript", "build", tempRoot, "--", "--quiet"],
        {
          cwd: projectRoot,
          stdio: "inherit",
        },
      );
    } catch {
      success = false;
    }
  });

  return { success, warningCount: 0 };
};

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  let { success } = run();
  process.exit(success ? 0 : 1);
}
