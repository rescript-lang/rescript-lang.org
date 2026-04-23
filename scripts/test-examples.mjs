import fs from "fs";
import { globSync } from "tinyglobby";
import path from "path";
import { createRequire } from "module";
import { fileURLToPath } from "url";
import child_process from "child_process";

const require = createRequire(import.meta.url);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..");
const tempFileRegex = /_tempFile\.res/g;
const rescriptCliPath = path.join(
  path.dirname(require.resolve("rescript/package.json")),
  "cli",
  "rescript.js",
);

const rescriptJson = `{
  "name": "temp",
  "namespace": false,
  "jsx": {
    "version": 4
  },
  "dependencies": [
    "@rescript/react"
  ],
  "package-specs": {
    "module": "esmodule"
  },
  "warnings": {
    "number": "-109-27-32"
  },
  "sources": [
    {
      "dir": "src"
    }
  ]
}`;

let splitLines = (content) => content.split("\n");

let isFenceLine = (line, fence) =>
  new RegExp(`^\\\`\\\`\\\`${fence}(?:\\s|$)`).test(line);

let classifyResFence = (line) => {
  if (isFenceLine(line, "res prelude")) {
    return "res-prelude";
  }

  if (isFenceLine(line, "res sig")) {
    return "res-sig";
  }

  if (isFenceLine(line, "res nocheck")) {
    return "res-nocheck";
  }

  if (isFenceLine(line, "res")) {
    return "res";
  }

  return null;
};

let classifyFence = (line) => {
  let resKind = classifyResFence(line);
  if (resKind != null) {
    return resKind;
  }

  if (line.startsWith("```js") || line.startsWith("```javascript")) {
    return "js";
  }

  if (line.startsWith("```ts") || line.startsWith("```typescript")) {
    return "ts";
  }

  return null;
};

let parseFile = (content) => {
  if (!/```res(?:\s|$)/.test(content)) {
    return;
  }

  let inWrappedBlock = false;
  let inIgnoredBlock = false;
  let moduleId = 0;

  return content
    .split("\n")
    .map((line) => {
      let kind = classifyResFence(line);

      if (kind === "res") {
        inWrappedBlock = true;
        return `/* _MODULE_EXAMPLE_START */ module M_${moduleId++} = {`;
      }

      if (kind === "res-prelude") {
        inWrappedBlock = true;
        return "/* _MODULE_PRELUDE_START */ include {";
      }

      if (kind === "res-sig") {
        inWrappedBlock = true;
        return `/* _MODULE_SIG_START */ module type M_${moduleId++} = {`;
      }

      if (kind === "res-nocheck") {
        inIgnoredBlock = true;
        return "";
      }

      if (line.startsWith("```")) {
        if (inWrappedBlock) {
          inWrappedBlock = false;
          return "} // _MODULE_END";
        }

        if (inIgnoredBlock) {
          inIgnoredBlock = false;
        }
      }

      if (inIgnoredBlock) {
        return "";
      }

      return inWrappedBlock ? line : "";
    })
    .join("\n");
};

let parseCodeTabLabels = (line) => {
  let match = line.match(/<CodeTab labels=\{(\[[^\n]+\])\}>/);

  if (match == null) {
    return null;
  }

  try {
    let labels = JSON.parse(match[1]);
    return Array.isArray(labels) ? labels : null;
  } catch {
    return null;
  }
};

let fenceKind = (line) => {
  if (classifyFence(line) === "js") {
    return "js";
  }

  if (line.startsWith("```res example")) {
    return "res-example";
  }

  return null;
};

let collectPreludeBlocks = (content) => {
  let lines = splitLines(content);
  let preludes = [];

  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith("```res prelude")) {
      continue;
    }

    let start = i + 1;
    let end = start;
    while (end < lines.length && !lines[end].startsWith("```")) {
      end++;
    }

    preludes.push({
      line: i + 1,
      content: lines.slice(start, end).join("\n"),
    });

    i = end;
  }

  return preludes;
};

let collectCodeTabTargets = ({ content, allowInsertions = false }) => {
  let lines = splitLines(content);
  let targets = [];
  let warnings = [];
  let inTargetTab = false;
  let tabStart = null;
  let tabEnd = null;
  let labels = null;
  let labelLine = null;
  let pendingRes = null;

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    let parsedLabels = parseCodeTabLabels(line);

    if (parsedLabels != null && parsedLabels.at(0) === "ReScript") {
      inTargetTab = true;
      tabStart = i;
      tabEnd = null;
      labels = parsedLabels;
      labelLine = i;
      pendingRes = null;
      continue;
    }

    if (inTargetTab && line.includes("</CodeTab>")) {
      tabEnd = i;
      if (pendingRes != null) {
        if (allowInsertions) {
          targets.push({
            tabStart,
            tabEnd,
            labels,
            labelLine,
            line: pendingRes.line,
            res: pendingRes,
            js: null,
          });
        } else if (
          labels.includes("JS Output") ||
          labels.includes("JS Output (Module)") ||
          labels.includes("JS Output (CommonJS)")
        ) {
          warnings.push({
            line: pendingRes.line,
            message: "missing paired JS Output block",
          });
        }
      }

      inTargetTab = false;
      tabStart = null;
      tabEnd = null;
      labels = null;
      labelLine = null;
      pendingRes = null;
      continue;
    }

    if (!inTargetTab) {
      continue;
    }

    let kind = fenceKind(line);

    if (kind === "res-example") {
      let start = i + 1;
      let end = start;
      while (end < lines.length && !lines[end].startsWith("```")) {
        end++;
      }

      pendingRes = {
        fenceStart: i,
        fenceEnd: end,
        line: i + 1,
        content: lines.slice(start, end).join("\n"),
      };
      i = end;
      continue;
    }

    if (kind === "js" && pendingRes != null) {
      let start = i + 1;
      let end = start;
      while (end < lines.length && !lines[end].startsWith("```")) {
        end++;
      }

      targets.push({
        tabStart,
        tabEnd,
        labels,
        labelLine,
        line: pendingRes.line,
        res: pendingRes,
        js: {
          fenceKind: kind,
          fenceStart: i,
          fenceEnd: end,
          content: lines.slice(start, end).join("\n"),
        },
      });

      pendingRes = null;
      i = end;
    }
  }

  return { targets, warnings };
};

let stripCompilerBoilerplate = (output) => {
  let normalized = output.replace(
    /^\/\/ Generated by ReScript, PLEASE EDIT WITH CARE\n(?:'use strict';\n)?\n*/,
    "",
  );

  return normalized.replace(/\n\/\*.*\*\/\s*$/s, "").trimEnd();
};

let buildSnippetSource = ({ preludes, pair }) => {
  let visiblePreludes = preludes
    .filter((prelude) => prelude.line < pair.line)
    .map((prelude) => prelude.content)
    .filter(Boolean);

  return [...visiblePreludes, pair.res.content].filter(Boolean).join("\n\n");
};

let formatCompilerError = ({ file, error }) => {
  let stderr =
    error?.stderr == null
      ? String(error?.message ?? "Unknown compiler error")
      : error.stderr.toString();

  return stderr
    .replace(tempFileRegex, path.relative(".", file))
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
    .replace(/(.*)\}(.*)\/\/ _MODULE_END/g, (_, before, after) => {
      return `${before}\`\`\`${after}`;
    })
    .trim();
};

let reportCompilerError = ({ logger, file, line, error }) => {
  logger.warn(`${file}${line == null ? "" : `:${line}`}`);
  logger.warn(formatCompilerError({ file, error }));
};

let runRescriptBuild = (tempRoot, stdio = "pipe") => {
  child_process.execFileSync(
    process.execPath,
    [rescriptCliPath, "build", tempRoot, "--quiet"],
    {
      cwd: projectRoot,
      stdio,
    },
  );
};

let compileSnippet = (tempRoot, source) => {
  fs.writeFileSync(path.join(tempRoot, "src", "_tempFile.res"), source);
  runRescriptBuild(tempRoot);

  return fs.readFileSync(path.join(tempRoot, "src", "_tempFile.js"), "utf8");
};

let rewriteCodeTabLabel = ({ lines, target }) => {
  if (target.labels.length === 1 && target.labels[0] === "ReScript") {
    lines[target.labelLine] = '<CodeTab labels={["ReScript", "JS Output"]}>';
  }
};

let applyJsOutputUpdate = ({ lines, target, compiledJs }) => {
  let nextLines = [...lines];
  let jsLines = compiledJs === "" ? [] : compiledJs.split("\n");

  if (target.js != null) {
    nextLines.splice(
      target.js.fenceStart + 1,
      target.js.fenceEnd - target.js.fenceStart - 1,
      ...jsLines,
    );
  } else {
    nextLines.splice(target.tabEnd, 0, "", "```js", ...jsLines, "```", "");
  }

  rewriteCodeTabLabel({ lines: nextLines, target });

  return nextLines;
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

export let collectCodeTabPairs = (content) => {
  let { targets, warnings } = collectCodeTabTargets({ content });

  return {
    pairs: targets.map((target) => ({
      line: target.line,
      res: {
        line: target.res.line,
        content: target.res.content,
      },
      js:
        target.js == null
          ? null
          : {
              content: target.js.content,
            },
    })),
    warnings,
  };
};

export let run = ({
  docsRoot = path.join(projectRoot, "markdown-pages", "docs"),
  tempRoot = path.join(projectRoot, "temp"),
  logger = console,
  update = false,
} = {}) => {
  logger.log("Running tests...");
  ensureTempProject(tempRoot);

  let success = true;
  let warningCount = 0;

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
      runRescriptBuild(tempRoot);
    } catch (error) {
      reportCompilerError({ logger, file, error });
      success = false;
      return;
    }

    let preludes = collectPreludeBlocks(content);
    let { targets, warnings: malformedWarnings } = collectCodeTabTargets({
      content,
      allowInsertions: update,
    });
    let nextLines = splitLines(content);

    for (let warning of malformedWarnings) {
      logger.warn(`${file}:${warning.line} ${warning.message}`);
      warningCount++;
    }

    for (let target of [...targets].reverse()) {
      if (!update) {
        continue;
      }

      let snippetSource = buildSnippetSource({ preludes, pair: target });
      let compiledJs;
      try {
        compiledJs = compileSnippet(tempRoot, snippetSource);
      } catch (error) {
        reportCompilerError({ logger, file, line: target.line, error });
        success = false;
        break;
      }
      let expectedJs = stripCompilerBoilerplate(compiledJs);
      let currentJs = target.js?.content.trimEnd() ?? null;

      if (update) {
        if (currentJs == null || expectedJs !== currentJs) {
          nextLines = applyJsOutputUpdate({
            lines: nextLines,
            target,
            compiledJs: expectedJs,
          });
        }
      }
    }

    let nextContent = nextLines.join("\n");
    if (update && nextContent !== content) {
      fs.writeFileSync(file, nextContent);
    }
  });

  return { success, warningCount };
};

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  let { success } = run({ update: process.argv.includes("--update") });
  process.exit(success ? 0 : 1);
}
