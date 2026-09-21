import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { parseSync, transformAsync, traverse, types } from "@babel/core";
import { homepageCompilerOptions } from "../../vite-react-compiler.mjs";

const homepageComponents = [
  {
    name: "LandingPage",
    directory: "app/routes",
    compiledNames: ["LandingPage"],
  },
  {
    name: "LandingPageCopyButton",
    directory: "src/components",
    compiledNames: ["LandingPageCopyButton"],
  },
  {
    name: "LandingPageIntro",
    directory: "src/components",
    compiledNames: ["LandingPageIntro"],
  },
  {
    name: "LandingPageInstallInstructions",
    directory: "src/components",
    compiledNames: ["LandingPageInstallInstructions"],
  },
  {
    name: "LandingPageTrustedBy",
    directory: "src/components",
    compiledNames: ["LandingPageTrustedBy"],
  },
];
const navbarComponents = [
  {
    name: "NavbarPrimary",
    directory: "src/components",
    compiledNames: [
      "NavbarPrimary",
      "NavbarPrimary$LeftContent",
      "NavbarPrimary$RightContent",
    ],
  },
];
const optedInComponents = [...homepageComponents, ...navbarComponents];
const optedInNames = optedInComponents.flatMap(
  ({ compiledNames }) => compiledNames,
);

async function transformComponent({ name, directory }) {
  const filename = fileURLToPath(
    new URL(`../../${directory}/${name}.jsx`, import.meta.url),
  );
  const result = await transformAsync(await readFile(filename, "utf8"), {
    filename,
    ast: true,
    code: false,
    babelrc: false,
    configFile: false,
    parserOpts: { plugins: ["jsx"] },
    presets: homepageCompilerOptions().presets.map((preset) => preset.preset),
  });
  assert.ok(result?.ast, `${name} must produce a Babel AST`);
  return result.ast;
}

function cacheBindings(ast) {
  return ast.program.body.flatMap((node) => {
    if (
      !types.isImportDeclaration(node) ||
      node.source.value !== "react/compiler-runtime"
    ) {
      return [];
    }
    return node.specifiers.flatMap((specifier) =>
      types.isImportSpecifier(specifier) &&
      types.isIdentifier(specifier.imported, { name: "c" })
        ? [specifier.local.name]
        : [],
    );
  });
}

function cachedComponentNames(ast) {
  const bindings = cacheBindings(ast);
  const names = new Set();
  traverse(ast, {
    CallExpression(path) {
      if (
        types.isIdentifier(path.node.callee) &&
        bindings.includes(path.node.callee.name)
      ) {
        const component = path.getFunctionParent();
        assert.ok(component?.isFunctionDeclaration());
        assert.ok(component.node.id);
        names.add(component.node.id.name);
      }
    },
  });
  return [...names].sort();
}

function isMemoCacheSentinel(node) {
  return (
    types.isStringLiteral(node, { value: "react.memo_cache_sentinel" }) ||
    (types.isTemplateLiteral(node) &&
      node.expressions.length === 0 &&
      node.quasis[0]?.value.cooked === "react.memo_cache_sentinel")
  );
}

function memoizedFunctionCount(ast) {
  const functions = new Set();
  traverse(ast, {
    CallExpression(path) {
      const { callee, arguments: args } = path.node;
      if (
        types.isMemberExpression(callee, { computed: false }) &&
        types.isIdentifier(callee.object, { name: "Symbol" }) &&
        types.isIdentifier(callee.property, { name: "for" }) &&
        args.length === 1 &&
        isMemoCacheSentinel(args[0])
      ) {
        const component = path.getFunctionParent();
        assert.ok(component, "memoization must belong to a component");
        functions.add(component.node);
      }
    },
  });
  return functions.size;
}

for (const component of optedInComponents) {
  test(`${component.name} opts in to React 19 compiler memoization`, async () => {
    const ast = await transformComponent(component);
    assert.deepEqual(cachedComponentNames(ast), component.compiledNames);
    assert.equal(memoizedFunctionCount(ast), component.compiledNames.length);
  });
}

test("unannotated eligible application components remain uncompiled", async () => {
  const ast = await transformComponent({
    name: "NavbarSecondary",
    directory: "src/components",
  });
  assert.deepEqual(cacheBindings(ast), []);
  assert.deepEqual(cachedComponentNames(ast), []);
  assert.equal(memoizedFunctionCount(ast), 0);
});

test("compiler file filtering includes generated docs application modules", () => {
  const { include, exclude } = homepageCompilerOptions();
  const matches = (filename) =>
    include.test(filename) &&
    !exclude.some((pattern) => pattern.test(filename));
  for (const filename of [
    "/repo/apps/docs/app/routes/LandingPageRoute.jsx",
    "/repo/apps/docs/app/routes/TryRoute.jsx?import",
    "/repo/apps/docs/app/layouts/HomepageLayoutRoute.jsx",
    "C:\\repo\\apps\\docs\\app\\routes\\LandingPageRoute.jsx",
    "/repo/apps/docs/src/components/NavbarSecondary.jsx",
    "/repo/apps/docs/src/common/Hooks.jsx?import",
    "/repo/apps/docs/src/data/BlogApi.jsx",
    "C:\\repo\\apps\\docs\\src\\components\\NavbarSecondary.jsx",
  ]) {
    assert.equal(matches(filename), true, filename);
  }
  for (const filename of [
    "/repo/apps/docs/app/routes/LandingPageRoute.res",
    "/repo/apps/docs/app/routes/LandingPageRoute.resi",
    "/repo/apps/docs/app/routes/LandingPageRoute.mjs",
    "/repo/apps/docs/app/routes/LandingPageRoute.jsx.map",
    "/repo/apps/docs/__tests__/LandingPage_.test.jsx",
    "/repo/apps/docs/build/client/LandingPageRoute.jsx",
    "/repo/apps/guide/app/routes/LandingPageRoute.jsx",
    "/repo/node_modules/example/apps/docs/app/routes/LandingPageRoute.jsx",
    "C:\\repo\\node_modules\\example\\apps\\docs\\app\\routes\\LandingPageRoute.jsx",
    "/repo/apps/guide/src/components/NavbarSecondary.jsx",
    "/repo/node_modules/example/apps/docs/src/components/NavbarSecondary.jsx",
    "\0rolldown/runtime.js",
  ]) {
    assert.equal(matches(filename), false, filename);
  }
});

test("the shared preset preserves annotation mode and excludes server compilation", () => {
  const [{ preset, rolldown }] = homepageCompilerOptions().presets;
  assert.deepEqual(preset().plugins, [
    [
      "babel-plugin-react-compiler",
      { compilationMode: "annotation", target: "19" },
    ],
  ]);
  assert.equal(
    rolldown.filter.code.test('function Example() { "use memo"; }'),
    true,
  );
  assert.equal(rolldown.filter.code.test("function Example() {}"), false);
  assert.equal(
    rolldown.applyToEnvironmentHook({ config: { consumer: "client" } }),
    true,
  );
  assert.equal(
    rolldown.applyToEnvironmentHook({ config: { consumer: "server" } }),
    false,
  );
  assert.deepEqual(rolldown.optimizeDeps.include, ["react/compiler-runtime"]);
});

test("the production homepage bundle contains its compiled components", async () => {
  const directory = new URL("../../build/client/assets/", import.meta.url);
  const filenames = (await readdir(directory)).filter((filename) =>
    /^LandingPageRoute-[^/]+\.js$/.test(filename),
  );
  assert.equal(filenames.length, 1, "the production homepage entry must exist");
  const contents = await readFile(new URL(filenames[0], directory), "utf8");
  const ast = parseSync(contents, { babelrc: false, configFile: false });
  assert.ok(ast);
  assert.equal(
    memoizedFunctionCount(ast),
    homepageComponents.flatMap(({ compiledNames }) => compiledNames).length,
  );
});

test("the production client bundle contains the compiled primary navbar", async () => {
  const directory = new URL("../../build/client/assets/", import.meta.url);
  const assets = await Promise.all(
    (await readdir(directory))
      .filter((filename) => filename.endsWith(".js"))
      .map(async (filename) => ({
        filename,
        contents: await readFile(new URL(filename, directory), "utf8"),
      })),
  );
  const matches = assets.filter(({ contents }) =>
    contents.includes("navbar-primary-left-content"),
  );
  assert.equal(matches.length, 1, "the production primary navbar must exist");
  const ast = parseSync(matches[0].contents, {
    babelrc: false,
    configFile: false,
  });
  assert.ok(ast);
  assert.equal(
    memoizedFunctionCount(ast),
    navbarComponents.flatMap(({ compiledNames }) => compiledNames).length,
  );
});

test("the production server leaves the annotated components uncompiled", async () => {
  const contents = await readFile(
    new URL("../../build/server/index.js", import.meta.url),
    "utf8",
  );
  const ast = parseSync(contents, { babelrc: false, configFile: false });
  assert.ok(ast);
  const annotatedComponents = [];
  traverse(ast, {
    FunctionDeclaration(path) {
      if (
        optedInNames.includes(path.node.id?.name) &&
        path.node.body.directives.some(
          (directive) => directive.value.value === "use memo",
        )
      ) {
        annotatedComponents.push(path.node.id.name);
      }
    },
  });
  assert.deepEqual(annotatedComponents.sort(), [...optedInNames].sort());
  assert.deepEqual(cacheBindings(ast), []);
  assert.equal(memoizedFunctionCount(ast), 0);
});
