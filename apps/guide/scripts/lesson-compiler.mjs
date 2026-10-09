import vm from "node:vm";
import { build } from "esbuild";

const sources = new Map();

async function fetchSource(url) {
  if (!sources.has(url)) {
    sources.set(
      url,
      (async () => {
        const response = await fetch(url, {
          signal: AbortSignal.timeout(15000),
        });
        if (!response.ok)
          throw new Error(
            `Could not load guide compiler asset ${url}: HTTP ${response.status}`,
          );
        return response.text();
      })(),
    );
  }
  try {
    return await sources.get(url);
  } catch (cause) {
    sources.delete(url);
    throw new Error(
      `Could not load guide compiler asset ${url}: ${cause.message}`,
      { cause },
    );
  }
}

export async function loadCompiler(
  bundleBaseUrl,
  version,
  moduleSystem,
  warnFlags,
) {
  const context = vm.createContext({ console });
  for (const path of [
    "compiler.js",
    "@rescript/react/cmij.js",
    "compiler-builtins/cmij.js",
  ]) {
    const url = `${bundleBaseUrl}/${version}/${path}`;
    vm.runInContext(await fetchSource(url), context, {
      filename: url,
      timeout: 10000,
    });
  }
  const compiler = context.rescript_compiler.make();
  if (`v${compiler.version}` !== version)
    throw new Error(
      `Expected guide compiler ${version}, received ${compiler.version}`,
    );
  compiler.setModuleSystem(moduleSystem === "esmodule" ? "es6" : "nodejs");
  compiler.setWarnFlags(warnFlags);
  compiler.setExperimentalFeatures([]);
  compiler.setJsxPreserveMode(false);
  return compiler;
}

// Match EvalIFrame's argument serialization and the checkpoint's space-joined log lines.
function serializeArg(arg) {
  if (arg === undefined) return "undefined";
  if (typeof arg === "object")
    return JSON.stringify(arg, Object.getOwnPropertyNames(arg));
  if (typeof arg === "function") return arg.toString();
  return arg;
}

export async function runProgram({ code, imports }) {
  const importCode = Object.entries(imports)
    .map(([name, url]) => `import * as ${name} from ${JSON.stringify(url)};`)
    .join("\n");
  const result = await build({
    // Bundle the runtime dependencies only; preserve the guide's executable JS verbatim.
    stdin: {
      contents: `${importCode}\nglobalThis.__guideRuntimeImports = {${Object.keys(imports).join(",")}};`,
      sourcefile: "guide-runtime.js",
    },
    bundle: true,
    format: "iife",
    write: false,
    logLevel: "silent",
    plugins: [
      {
        name: "guide-cdn-runtime",
        setup(build) {
          build.onResolve({ filter: /^https?:\/\// }, (args) => ({
            path: args.path,
            namespace: "guide-cdn",
          }));
          build.onResolve({ filter: /.*/, namespace: "guide-cdn" }, (args) => ({
            path: new URL(args.path, args.importer).href,
            namespace: "guide-cdn",
          }));
          build.onLoad(
            { filter: /.*/, namespace: "guide-cdn" },
            async (args) => ({
              contents: await fetchSource(args.path),
              loader: "js",
            }),
          );
        },
      },
    ],
  });
  const logs = [];
  const console = Object.fromEntries(
    ["log", "warn", "error"].map((level) => [
      level,
      (...args) => logs.push({ level, content: args.map(serializeArg) }),
    ]),
  );
  const context = vm.createContext({ console });
  vm.runInContext(result.outputFiles[0].text, context, { timeout: 1000 });
  Object.assign(context, context.__guideRuntimeImports);
  vm.runInContext(code, context, { timeout: 1000 });
  return logs;
}
