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
const tempModuleName = "Example";
const tempSourceRegex = new RegExp(`${tempModuleName}\\.res`, "g");
const rescriptCliPath = path.join(
  path.dirname(require.resolve("rescript/package.json")),
  "cli",
  "rescript.js",
);

let makeRescriptJson = ({ preserve = false } = {}) => `{
  "name": "temp",
  "namespace": false,
  "jsx": {
    "version": 4${preserve ? ',\n    "preserve": true' : ""}
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

  if (line.startsWith("```jsx")) {
    return "jsx";
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
        return `/* _MODULE_CHECKED_START */ module M_${moduleId++} = {`;
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

let isEligibleReScriptCodeTab = (labels) =>
  labels?.at(0) === "ReScript" && labels.at(1) !== "TypeScript Output";

let fenceKind = (line) => {
  let kind = classifyFence(line);

  if (kind === "js" || kind === "jsx") {
    return "js";
  }

  if (kind === "res") {
    return "res";
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

let collectFenceBlock = (lines, fenceStart) => {
  let start = fenceStart + 1;
  let end = start;

  while (end < lines.length && !lines[end].startsWith("```")) {
    end++;
  }

  return {
    fenceStart,
    fenceEnd: end,
    content: lines.slice(start, end).join("\n"),
  };
};

let collectCodeTabTargets = ({ content, allowInsertions = false }) => {
  let lines = splitLines(content);
  let targets = [];
  let warnings = [];
  let currentTarget = null;

  for (let i = 0; i < lines.length; i++) {
    let line = lines[i];
    let parsedLabels = parseCodeTabLabels(line);

    if (parsedLabels != null && isEligibleReScriptCodeTab(parsedLabels)) {
      currentTarget = {
        tabStart: i,
        tabEnd: null,
        labels: parsedLabels,
        labelLine: i,
        res: null,
        js: null,
        jsx: null,
      };
      continue;
    }

    if (currentTarget != null && line.includes("</CodeTab>")) {
      currentTarget.tabEnd = i;

      if (currentTarget.res != null) {
        if (allowInsertions) {
          targets.push({
            ...currentTarget,
            line: currentTarget.res.line,
          });
        } else if (
          currentTarget.js != null ||
          currentTarget.labels.includes("JS Output") ||
          currentTarget.labels.includes("JS Output (Module)") ||
          currentTarget.labels.includes("JS Output (CommonJS)")
        ) {
          if (currentTarget.js != null) {
            targets.push({
              ...currentTarget,
              line: currentTarget.res.line,
            });
          } else {
            warnings.push({
              line: currentTarget.res.line,
              message: "missing paired JS Output block",
            });
          }
        }
      }

      currentTarget = null;
      continue;
    }

    if (currentTarget == null) {
      continue;
    }

    let kind = fenceKind(line);

    if (kind === "res") {
      let block = collectFenceBlock(lines, i);

      if (currentTarget.res == null) {
        currentTarget.res = {
          ...block,
          line: i + 1,
        };
      }

      i = block.fenceEnd;
      continue;
    }

    if (kind === "js" && currentTarget.res != null) {
      let block = collectFenceBlock(lines, i);
      let fence = classifyFence(line);

      if (fence === "jsx" && currentTarget.jsx == null) {
        currentTarget.jsx = {
          ...block,
          fenceKind: "jsx",
        };
      } else if (fence === "js" && currentTarget.js == null) {
        currentTarget.js = {
          ...block,
          fenceKind: "js",
        };
      }

      i = block.fenceEnd;
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

let tempModulePath = (tempRoot, extension) =>
  path.join(tempRoot, "src", `${tempModuleName}.${extension}`);

let formatCompilerError = ({ file, error }) => {
  let stderr =
    error?.stderr == null
      ? String(error?.message ?? "Unknown compiler error")
      : error.stderr.toString();

  return stderr
    .replace(tempSourceRegex, path.relative(".", file))
    .replace(
      /\/\* _MODULE_(CHECKED|EXAMPLE|PRELUDE|SIG)_START \*\/.+/g,
      (_, capture) => {
        if (capture === "CHECKED" || capture === "EXAMPLE") {
          return "```res";
        }

        return "```res " + (capture === "PRELUDE" ? "prelude" : "sig");
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

let readCompiledSnippet = (tempRoot) => {
  let jsxPath = tempModulePath(tempRoot, "jsx");
  let jsPath = tempModulePath(tempRoot, "js");
  let outputPath = fs.existsSync(jsxPath) ? jsxPath : jsPath;

  return fs.readFileSync(outputPath, "utf8");
};

let compileSnippet = (tempRoot, source) => {
  fs.writeFileSync(tempModulePath(tempRoot, "res"), source);
  runRescriptBuild(tempRoot);

  return readCompiledSnippet(tempRoot);
};

let usesJsxRuntime = (compiledJs) => compiledJs.includes("JsxRuntime");

let rewriteCodeTabLabels = ({ lines, target, needsPreserveTab }) => {
  let nextLabels =
    target.labels.length === 1 && target.labels[0] === "ReScript"
      ? ["ReScript", "JS Output"]
      : [...target.labels];

  let withoutPreserve = nextLabels.filter(
    (label) => label !== "JSX Preserved Output",
  );
  let finalLabels = needsPreserveTab
    ? [...withoutPreserve, "JSX Preserved Output"]
    : withoutPreserve;

  let formattedLabels = `[${finalLabels.map((label) => JSON.stringify(label)).join(", ")}]`;

  lines[target.labelLine] = `<CodeTab labels={${formattedLabels}}>`;
};

let splitBlockLines = (content) => (content === "" ? [] : content.split("\n"));

let buildDerivedFenceBlock = ({ fence, content }) => [
  "",
  `\`\`\`${fence}`,
  ...splitBlockLines(content),
  "```",
  "",
];

let expandFenceRangeForBlankLines = ({ lines, fenceStart, fenceEnd }) => {
  let start = fenceStart;
  let end = fenceEnd;

  if (start > 0 && lines[start - 1] === "") {
    start--;
  }

  if (end + 1 < lines.length && lines[end + 1] === "") {
    end++;
  }

  return {
    start,
    deleteCount: end - start + 1,
  };
};

let findCodeTabEnd = ({ lines, target }) => {
  for (let i = target.tabStart; i < lines.length; i++) {
    if (lines[i].includes("</CodeTab>")) {
      return i;
    }
  }

  return lines.length;
};

let applyDerivedOutputUpdate = ({ lines, target, compiledJs, compiledJsx }) => {
  let nextLines = [...lines];
  let needsPreserveTab = compiledJsx != null;

  if (target.jsx != null) {
    if (needsPreserveTab) {
      nextLines.splice(
        target.jsx.fenceStart + 1,
        target.jsx.fenceEnd - target.jsx.fenceStart - 1,
        ...splitBlockLines(compiledJsx),
      );
    } else {
      let { start, deleteCount } = expandFenceRangeForBlankLines({
        lines: nextLines,
        fenceStart: target.jsx.fenceStart,
        fenceEnd: target.jsx.fenceEnd,
      });

      nextLines.splice(start, deleteCount);
    }
  }

  if (target.js != null) {
    nextLines.splice(
      target.js.fenceStart + 1,
      target.js.fenceEnd - target.js.fenceStart - 1,
      ...splitBlockLines(compiledJs),
    );
  } else {
    nextLines.splice(
      findCodeTabEnd({ lines: nextLines, target }),
      0,
      ...buildDerivedFenceBlock({ fence: "js", content: compiledJs }),
    );
  }

  if (needsPreserveTab && target.jsx == null) {
    nextLines.splice(
      findCodeTabEnd({ lines: nextLines, target }),
      0,
      ...buildDerivedFenceBlock({ fence: "jsx", content: compiledJsx }),
    );
  }

  rewriteCodeTabLabels({ lines: nextLines, target, needsPreserveTab });

  return nextLines;
};

let ensureTempProject = ({ tempRoot, preserve = false }) => {
  fs.mkdirSync(path.join(tempRoot, "src"), { recursive: true });
  fs.writeFileSync(
    path.join(tempRoot, "rescript.json"),
    makeRescriptJson({ preserve }),
  );
  fs.writeFileSync(tempModulePath(tempRoot, "res"), "");
  let tempNodeModules = path.join(tempRoot, "node_modules", "@rescript");
  let tempReactPackage = path.join(tempNodeModules, "react");
  if (!fs.existsSync(tempReactPackage)) {
    fs.mkdirSync(tempNodeModules, { recursive: true });
    fs.cpSync(
      path.join(projectRoot, "node_modules", "@rescript", "react"),
      tempReactPackage,
      {
        recursive: true,
      },
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
  let runtimeTempRoot = path.join(
    path.dirname(tempRoot),
    path.basename(tempRoot) + "-js-output",
  );
  let preserveTempRoot = path.join(
    path.dirname(tempRoot),
    path.basename(tempRoot) + "-jsx-preserve",
  );

  ensureTempProject({ tempRoot });
  if (update) {
    ensureTempProject({ tempRoot: runtimeTempRoot });
    ensureTempProject({ tempRoot: preserveTempRoot, preserve: true });
  }

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

    fs.writeFileSync(tempModulePath(tempRoot, "res"), parsedResult);
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
      let compiledJsx = null;
      try {
        compiledJs = compileSnippet(
          update ? runtimeTempRoot : tempRoot,
          snippetSource,
        );
        let expectedJs = stripCompilerBoilerplate(compiledJs);

        if (usesJsxRuntime(expectedJs)) {
          compiledJsx = stripCompilerBoilerplate(
            compileSnippet(preserveTempRoot, snippetSource),
          );
        }

        compiledJs = expectedJs;
      } catch (error) {
        reportCompilerError({ logger, file, line: target.line, error });
        success = false;
        break;
      }

      if (update) {
        nextLines = applyDerivedOutputUpdate({
          lines: nextLines,
          target,
          compiledJs,
          compiledJsx,
        });
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
