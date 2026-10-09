import fs from "fs";
import { globSync } from "tinyglobby";
import path from "path";
import { createRequire } from "module";
import { fileURLToPath } from "url";
import child_process from "child_process";
import { format } from "oxfmt";
import { parseSync } from "@babel/core";

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
const rescriptReactPackageRoot = path.dirname(
  require.resolve("@rescript/react/package.json"),
);

let makeRescriptJson = ({ preserve = false, module = "esmodule" } = {}) => `{
  "name": "temp",
  "namespace": false,
  "jsx": {
    "version": 4${preserve ? ',\n    "preserve": true' : ""}
  },
  "dependencies": [
    "@rescript/react"
  ],
  "package-specs": {
    "module": "${module}"
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

let classifyFence = (info) => {
  let [language, modifier] = info.trim().split(/\s+/);
  if (language === "res" || language === "rescript" || language === "resi") {
    if (modifier === "nocheck") return "res-nocheck";
    if (language === "resi" || modifier === "sig") return "res-sig";
    if (modifier === "prelude") return "res-prelude";
    return "res";
  }
  if (language === "js" || language === "javascript") return "js";
  if (language === "jsx") return "jsx";
  return null;
};

// Scan all fences, including unchecked languages, so tags and nested fence text
// inside examples cannot accidentally become tooling instructions.
let collectFenceBlocks = (content) => {
  let lines = splitLines(content);
  let blocks = [];
  let warnings = [];
  for (let i = 0; i < lines.length; i++) {
    let match = lines[i].match(/^(\s*)(`{3,}|~{3,})(.*)$/);
    if (match == null) continue;
    let [, indent, delimiter, info] = match;
    let end = i + 1;
    let closing = new RegExp(`^\\s*${delimiter[0]}{${delimiter.length},}\\s*$`);
    while (end < lines.length && !closing.test(lines[end])) end++;
    if (end === lines.length) {
      warnings.push({ line: i + 1, message: "unclosed code fence" });
    }
    blocks.push({
      fenceStart: i,
      fenceEnd: end,
      line: i + 1,
      indent,
      kind: classifyFence(info),
      content: lines
        .slice(i + 1, end)
        .map((line) =>
          line.startsWith(indent) ? line.slice(indent.length) : line,
        )
        .join("\n"),
    });
    i = end;
  }
  return { blocks, warnings };
};

let parseFile = (content, blocks) => {
  let lines = splitLines(content).map(() => "");
  let moduleId = 0;
  let checked = false;
  for (let block of blocks) {
    let marker;
    if (block.kind === "res") {
      marker = `/* _MODULE_CHECKED_START */ module M_${moduleId++} = {`;
    } else if (block.kind === "res-prelude") {
      marker = "/* _MODULE_PRELUDE_START */ include {";
    } else if (block.kind === "res-sig") {
      marker = `/* _MODULE_SIG_START */ module type M_${moduleId++} = {`;
    } else {
      continue;
    }
    checked = true;
    lines[block.fenceStart] = marker;
    block.content.split("\n").forEach((line, i) => {
      lines[block.fenceStart + 1 + i] = line;
    });
    lines[block.fenceEnd] = "} // _MODULE_END";
  }
  return checked ? lines.join("\n") : null;
};

let parseCodeTabLabels = (tag) => {
  let match = tag.match(/labels\s*=\s*\{(\[[\s\S]*?\])\}/);
  if (match == null) return null;
  try {
    let labels = JSON.parse(match[1]);
    return Array.isArray(labels) &&
      labels.every((label) => typeof label === "string")
      ? labels
      : null;
  } catch {
    return null;
  }
};

let outputKind = (label) => {
  if (label === "JS Output" || label === "JS Output (Module)")
    return "esmodule";
  if (label === "JS Output (CommonJS)") return "commonjs";
  if (label === "JSX Preserved Output") return "preserve";
  return null;
};

let collectCodeTabTargets = ({ content, blocks, allowInsertions = false }) => {
  let lines = splitLines(content);
  let targets = [];
  let warnings = [];
  let current = null;
  let blocksByStart = new Map(blocks.map((block) => [block.fenceStart, block]));
  let warn = (line, message) => warnings.push({ line: line + 1, message });

  let finish = (tabEnd) => {
    let { labels, tabBlocks } = current;
    let res = tabBlocks.find(
      (block) => block.kind === "res" || block.kind === "res-prelude",
    );
    let repairableMissingOutput =
      allowInsertions &&
      res != null &&
      tabBlocks.length === 1 &&
      labels.length > 1 &&
      labels.slice(1).every((label) => outputKind(label) != null);
    if (labels.length !== tabBlocks.length && !repairableMissingOutput) {
      warn(
        current.tabStart,
        "CodeTab labels do not match its code blocks (missing paired JS Output block or extra fence)",
      );
      return;
    }
    if (res == null) return;
    let outputs = labels.flatMap((label, index) => {
      let kind = outputKind(label);
      if (kind == null) return [];
      let block = tabBlocks[index];
      if (
        block != null &&
        block.kind !== (kind === "preserve" ? "jsx" : "js")
      ) {
        warn(
          block.fenceStart,
          `expected ${kind === "preserve" ? "jsx" : "js"} fence for ${label}`,
        );
        return [];
      }
      return [{ label, kind, block }];
    });
    if (allowInsertions && labels.length === 1 && tabBlocks.length === 1) {
      outputs.push({ label: "JS Output", kind: "esmodule", block: null });
    }
    if (outputs.length === 0) return;
    // Comparison tabs may show equivalent ReScript spellings. The first
    // checked source owns the derived output; page compilation checks all of them.
    targets.push({ ...current, tabEnd, res, line: res.line, outputs });
  };

  for (let i = 0; i < lines.length; i++) {
    let block = blocksByStart.get(i);
    if (block != null) {
      if (current != null) current.tabBlocks.push(block);
      i = block.fenceEnd;
      continue;
    }
    if (/^\s*<CodeTab\b/.test(lines[i])) {
      if (current != null)
        warn(current.tabStart, "unclosed CodeTab before the next CodeTab");
      let labelEnd = i;
      while (labelEnd < lines.length && !lines[labelEnd].includes(">"))
        labelEnd++;
      let labels = parseCodeTabLabels(lines.slice(i, labelEnd + 1).join("\n"));
      current = null;
      if (labels == null) {
        warn(i, "invalid CodeTab labels");
      } else {
        current = { tabStart: i, labelEnd, labels, tabBlocks: [] };
      }
      i = labelEnd;
      continue;
    }
    if (/^\s*<\/\s*CodeTab\s*>/.test(lines[i])) {
      if (!/^\s*<\/CodeTab>\s*$/.test(lines[i])) {
        warn(i, "malformed CodeTab closing tag; use </CodeTab>");
      } else if (current == null) {
        warn(i, "unexpected CodeTab closing tag");
      } else {
        finish(i);
      }
      current = null;
    }
  }
  if (current != null) warn(current.tabStart, "unclosed CodeTab");
  return { targets, warnings };
};

let stripCompilerBoilerplate = (output) => {
  let normalized = output.replace(
    /^\/\/ Generated by ReScript, PLEASE EDIT WITH CARE\n(?:'use strict';\n)?\n*/,
    "",
  );

  return normalized.replace(/\n\/\*(?:(?!\/\*)[\s\S])*?\*\/\s*$/, "").trimEnd();
};

let buildSnippetSource = ({ blocks, target }) => {
  let preludes = blocks
    .filter((block) => block.kind === "res-prelude" && block.line < target.line)
    .map((block) => block.content)
    .filter(Boolean)
    .join("\n\n");
  let source = [preludes, target.res.content].filter(Boolean).join("\n\n");
  let contextName = "ExamplePrelude";
  while (source.includes(contextName)) contextName += "Context";
  return {
    source,
    // Page-level examples have a nested scope and can shadow prelude modules
    // or types. Keep that context available if a flat snippet cannot compile.
    scopedSource:
      preludes === ""
        ? null
        : `module ${contextName} = {\n${preludes}\n}\nopen ${contextName}\n${target.res.content}`,
  };
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

let compileSnippet = (tempRoot, { source, scopedSource }) => {
  fs.writeFileSync(tempModulePath(tempRoot, "res"), source);
  try {
    runRescriptBuild(tempRoot);
  } catch (error) {
    if (
      scopedSource == null ||
      !/Multiple definition of the (module|type) name/.test(
        error.stderr?.toString() ?? "",
      )
    )
      throw error;
    fs.writeFileSync(tempModulePath(tempRoot, "res"), scopedSource);
    runRescriptBuild(tempRoot);
  }

  return readCompiledSnippet(tempRoot);
};

let usesJsxRuntime = (compiledJs) =>
  /from ["']react\/jsx-runtime["']/.test(compiledJs);

let formatOutput = async (output, preserve = false) => {
  let { code, errors } = await format(
    preserve ? "Example.jsx" : "Example.js",
    output,
    {
      printWidth: 80,
      objectWrap: "collapse",
    },
  );
  if (errors.length > 0)
    throw new Error(errors.map((error) => error.message).join("\n"));
  return code.trimEnd();
};

// Compare syntax rather than printed lines: quotes, wrapping and explanatory
// comments can differ without changing the generated program.
let normalizeOutput = (output) => {
  if (output == null) return null;
  let ast = parseSync(output, {
    babelrc: false,
    configFile: false,
    sourceType: "unambiguous",
    parserOpts: { plugins: ["jsx"] },
  });
  let metadata = new Set([
    "start",
    "end",
    "loc",
    "extra",
    "leadingComments",
    "trailingComments",
    "innerComments",
  ]);
  return JSON.stringify(ast.program, (key, value) =>
    metadata.has(key) ? undefined : value,
  );
};

let applyDerivedOutputUpdate = ({ lines, target, outputs }) => {
  let nextLines = [...lines];
  let labels = [...target.labels];
  for (let { content, label } of outputs) {
    if (content == null) labels = labels.filter((value) => value !== label);
    else if (!labels.includes(label)) labels.push(label);
  }
  // Work backwards to keep original fence positions valid.
  for (let output of [...outputs].sort(
    (a, b) =>
      (b.block?.fenceStart ?? target.tabEnd) -
        (a.block?.fenceStart ?? target.tabEnd) ||
      outputs.indexOf(b) - outputs.indexOf(a),
  )) {
    let { block, content, kind } = output;
    if (block != null) {
      if (content == null) {
        nextLines.splice(
          block.fenceStart,
          block.fenceEnd - block.fenceStart + 1,
        );
      } else {
        nextLines.splice(
          block.fenceStart + 1,
          block.fenceEnd - block.fenceStart - 1,
          ...content.split("\n").map((line) => block.indent + line),
        );
      }
    } else if (content != null) {
      let indent = target.res.indent;
      nextLines.splice(
        target.tabEnd,
        0,
        "",
        `${indent}\`\`\`${kind === "preserve" ? "jsx" : "js"}`,
        ...content.split("\n").map((line) => indent + line),
        `${indent}\`\`\``,
        "",
      );
    }
  }
  let indent = lines[target.tabStart].match(/^\s*/)[0];
  nextLines.splice(
    target.tabStart,
    target.labelEnd - target.tabStart + 1,
    `${indent}<CodeTab labels={[${labels.map((label) => JSON.stringify(label)).join(", ")}]}>`,
  );
  return nextLines;
};

let ensureTempProject = ({
  tempRoot,
  preserve = false,
  module = "esmodule",
}) => {
  fs.mkdirSync(path.join(tempRoot, "src"), { recursive: true });
  fs.writeFileSync(
    path.join(tempRoot, "rescript.json"),
    makeRescriptJson({ preserve, module }),
  );
  fs.writeFileSync(tempModulePath(tempRoot, "res"), "");
  let tempNodeModules = path.join(tempRoot, "node_modules", "@rescript");
  let tempReactPackage = path.join(tempNodeModules, "react");
  if (!fs.existsSync(tempReactPackage)) {
    fs.mkdirSync(tempNodeModules, { recursive: true });
    fs.cpSync(rescriptReactPackageRoot, tempReactPackage, {
      recursive: true,
    });
  }
};

export let collectCodeTabPairs = (content) => {
  let { blocks, warnings: fenceWarnings } = collectFenceBlocks(content);
  let { targets, warnings } = collectCodeTabTargets({ content, blocks });
  return {
    pairs: targets.map((target) => ({
      line: target.line,
      res: { line: target.res.line, content: target.res.content },
      js:
        target.outputs.find((output) => output.kind !== "preserve")?.block ??
        null,
    })),
    warnings: [...fenceWarnings, ...warnings],
  };
};

export let run = async ({
  docsRoot = path.join(projectRoot, "markdown-pages", "docs"),
  tempRoot = path.join(projectRoot, "temp"),
  logger = console,
  update = false,
  includeBlog = false,
  patterns = ["{manual,react,guides}/**/*.mdx", "../syntax-lookup/**/*.mdx"],
} = {}) => {
  logger.log("Running tests...");
  ensureTempProject({ tempRoot });
  let projects = new Map();
  let outputProject = (kind) => {
    if (!projects.has(kind)) {
      let root = path.join(tempRoot, kind);
      ensureTempProject({
        tempRoot: root,
        preserve: kind === "preserve",
        module: kind === "commonjs" ? "commonjs" : "esmodule",
      });
      projects.set(kind, root);
    }
    return projects.get(kind);
  };
  let success = true;
  let warningCount = 0;
  let mismatchCount = 0;
  let errorCount = 0;
  let checkedFiles = 0;
  let blogFiles = globSync("../blog/**/*.mdx", {
    cwd: docsRoot,
    absolute: true,
  });
  let files = globSync(patterns, { cwd: docsRoot, absolute: true });
  if (includeBlog) files.push(...blogFiles);
  let blogPaths = new Set(blogFiles.map((file) => path.resolve(file)));
  let skippedFiles = includeBlog
    ? 0
    : blogFiles.filter((file) => !files.includes(file)).length;
  if (skippedFiles > 0)
    logger.log(
      `Skipping ${skippedFiles} historical blog pages; use --include-blog for a read-only compiler audit.`,
    );

  for (let file of [...new Set(files)].sort()) {
    let content = fs.readFileSync(file, "utf8");
    let { blocks, warnings: fenceWarnings } = collectFenceBlocks(content);
    let isBlog = blogPaths.has(path.resolve(file));
    let updateFile = update && !isBlog;
    let { targets, warnings: tabWarnings } = collectCodeTabTargets({
      content,
      blocks,
      allowInsertions: updateFile,
    });
    let warnings = [...fenceWarnings, ...tabWarnings];
    for (let warning of warnings) {
      logger.warn(`${file}:${warning.line} ${warning.message}`);
      warningCount++;
      success = false;
    }
    // Never rewrite a malformed page, even if some tabs can be parsed.
    if (warnings.length > 0) continue;
    let source = parseFile(content, blocks);
    if (source == null) continue;
    checkedFiles++;
    fs.writeFileSync(tempModulePath(tempRoot, "res"), source);
    try {
      logger.log("testing examples in", file);
      runRescriptBuild(tempRoot);
    } catch (error) {
      reportCompilerError({ logger, file, error });
      success = false;
      errorCount++;
      continue;
    }
    let nextLines = splitLines(content);
    let fileSuccess = true;
    for (let target of [...targets].reverse()) {
      let snippetSource = buildSnippetSource({ blocks, target });
      try {
        let outputs = [];
        let esm = null;
        let requested = [...target.outputs];
        // Only add a preserved JSX tab to an ESM example, never to TypeScript
        // output or unrelated comparison tabs.
        if (
          updateFile &&
          requested.some((output) => output.kind === "esmodule") &&
          !requested.some((output) => output.kind === "preserve")
        ) {
          requested.push({
            label: "JSX Preserved Output",
            kind: "preserve",
            block: null,
          });
        }
        for (let output of requested) {
          let compiled;
          if (output.kind === "preserve") {
            esm ??= stripCompilerBoilerplate(
              compileSnippet(outputProject("esmodule"), snippetSource),
            );
            compiled = usesJsxRuntime(esm)
              ? stripCompilerBoilerplate(
                  compileSnippet(outputProject("preserve"), snippetSource),
                )
              : null;
          } else {
            compiled = stripCompilerBoilerplate(
              compileSnippet(outputProject(output.kind), snippetSource),
            );
            if (output.kind === "esmodule") esm = compiled;
          }
          let expected =
            compiled == null
              ? null
              : await formatOutput(compiled, output.kind === "preserve");
          outputs.push({ ...output, content: expected });
          // An absent optional preserved tab is fine during ordinary checks.
          if (
            !updateFile &&
            (output.block != null || output.kind !== "preserve")
          ) {
            let shown =
              output.block == null
                ? null
                : stripCompilerBoilerplate(output.block.content);
            if (normalizeOutput(shown) !== normalizeOutput(expected)) {
              let advice = isBlog
                ? "historical blog output needs review against its original compiler version."
                : "run yarn test --update to refresh generated output.";
              logger.warn(
                `${file}:${output.block?.line ?? target.line} stale ${output.label}; ${advice}`,
              );
              mismatchCount++;
              success = false;
            }
          }
        }
        if (updateFile)
          nextLines = applyDerivedOutputUpdate({
            lines: nextLines,
            target,
            outputs,
          });
      } catch (error) {
        reportCompilerError({ logger, file, line: target.line, error });
        success = false;
        fileSuccess = false;
        errorCount++;
      }
    }
    let nextContent = nextLines.join("\n");
    if (updateFile && fileSuccess && nextContent !== content)
      fs.writeFileSync(file, nextContent);
  }
  logger.log(
    `Checked ${checkedFiles} pages: ${mismatchCount} stale outputs, ${warningCount} malformed blocks, ${errorCount} compilation or parsing errors.`,
  );
  return {
    success,
    warningCount,
    mismatchCount,
    errorCount,
    checkedFiles,
    skippedFiles,
  };
};

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  let patterns = process.argv
    .slice(2)
    .filter((argument) => !argument.startsWith("--"));
  let { success } = await run({
    update: process.argv.includes("--update"),
    includeBlog: process.argv.includes("--include-blog"),
    ...(patterns.length > 0 ? { patterns } : {}),
  });
  process.exit(success ? 0 : 1);
}
