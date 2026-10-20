import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  mkdtempSync,
  mkdirSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import routes from "../../app/routes.js";
import { loadRoutes } from "../../route-config.mjs";
import {
  concretePaths,
  generateRouteTypes,
  outputPath,
  renderPathType,
} from "../../generate-route-types.mjs";

function temporaryDirectory(t) {
  const directory = mkdtempSync(join(tmpdir(), "rescript-routes-"));
  t.after(() => rmSync(directory, { recursive: true, force: true }));
  return directory;
}

test("collects nested routes and index pages through pathless layouts", () => {
  assert.deepEqual(
    concretePaths([
      {
        children: [
          { index: true },
          {
            path: "docs",
            children: [
              { index: true },
              { children: [{ path: "manual", children: [{ path: "intro" }] }] },
              { path: "/brand" },
            ],
          },
        ],
      },
      { path: "docs/manual/intro" },
    ]),
    ["/", "/brand", "/docs", "/docs/manual", "/docs/manual/intro"],
  );
});

test("excludes catch-all and parameter patterns, including their descendants", () => {
  assert.deepEqual(
    concretePaths([
      { index: true },
      { path: "*" },
      { path: "files/*" },
      { path: "blog/:slug", children: [{ path: "edit" }] },
      { path: ":lang?/docs" },
      { path: "docs?" },
      { children: [] },
    ]),
    ["/"],
  );
});

test("the committed type matches the actual React Router configuration", () => {
  assert.equal(readFileSync(outputPath, "utf8"), renderPathType(routes));
  const paths = concretePaths(routes);
  for (const path of [
    "/try",
    "/brand",
    "/packages",
    "/syntax-lookup",
    "/docs/manual/api",
    "/docs/manual/migrate-to-v12",
    "/docs/manual/rescript-for-javascript-developers",
    "/docs/manual/api/dom/storage",
    "/blog/retreat-recap-2026",
  ])
    assert.ok(paths.includes(path), `Missing route: ${path}`);
  for (const path of [
    "/undefined",
    "/*",
    "/syntax-lookup/decorator_obj",
    "/syntax-lookup/operators_triangle_pipe",
  ])
    assert.ok(!paths.includes(path), `Stale route: ${path}`);
});

test("discovers added and removed MDX pages and API modules", (t) => {
  const contentDirectory = temporaryDirectory(t);
  for (const prefix of [
    "blog",
    "community",
    "docs/manual/api",
    "docs/react",
    "docs/guides",
    "syntax-lookup",
    "docs/api",
  ])
    mkdirSync(join(contentDirectory, prefix), { recursive: true });
  for (const library of ["stdlib", "dom", "belt"])
    writeFileSync(
      join(contentDirectory, "docs/api", `${library}.json`),
      JSON.stringify({ [library]: {}, [`${library}/example`]: {} }),
    );
  mkdirSync(join(contentDirectory, "blog/archived"));
  writeFileSync(
    join(contentDirectory, "blog/archived/old-post.mdx"),
    "# Old post",
  );
  writeFileSync(join(contentDirectory, "blog/ignored.txt"), "Ignored");
  writeFileSync(
    join(contentDirectory, "docs/manual/api/ignored.mdx"),
    "Ignored",
  );
  writeFileSync(
    join(contentDirectory, "docs/manual/api-extra.mdx"),
    "# API extra",
  );
  const options = {
    contentDirectory,
    apiDirectory: join(contentDirectory, "docs/api"),
  };
  const before = loadRoutes(options);
  const beforePaths = concretePaths(before.routes);
  assert.ok(beforePaths.includes("/blog/archived/old-post"));
  assert.ok(beforePaths.includes("/docs/manual/api-extra"));
  assert.ok(beforePaths.includes("/docs/manual/api/dom/example"));
  assert.ok(!beforePaths.includes("/blog/ignored"));
  assert.ok(!beforePaths.includes("/docs/manual/api/ignored"));
  assert.deepEqual(before.stdlibPaths, ["docs/manual/api/stdlib/example"]);

  rmSync(join(contentDirectory, "blog/archived/old-post.mdx"));
  writeFileSync(join(contentDirectory, "blog/new-post.mdx"), "# New post");
  writeFileSync(
    join(contentDirectory, "docs/api/stdlib.json"),
    JSON.stringify({ stdlib: {}, "stdlib/newmodule": {} }),
  );
  const after = concretePaths(loadRoutes(options).routes);
  assert.ok(!after.includes("/blog/archived/old-post"));
  assert.ok(after.includes("/blog/new-post"));
  assert.ok(!after.includes("/docs/manual/api/stdlib/example"));
  assert.ok(after.includes("/docs/manual/api/stdlib/newmodule"));
});

test("check mode detects missing and stale files without writing them", (t) => {
  const destination = join(temporaryDirectory(t), "Path.res");
  const routeConfig = [{ index: true }, { path: "new-route" }];
  const options = { routes: routeConfig, destination };
  assert.equal(generateRouteTypes({ ...options, check: true }), false);
  assert.throws(() => readFileSync(destination), { code: "ENOENT" });
  assert.equal(generateRouteTypes(options), true);
  assert.equal(generateRouteTypes({ ...options, check: true }), true);
  const source = readFileSync(destination, "utf8");
  assert.match(source, /#"\/new-route"/);
  writeFileSync(destination, source + "// stale\n");
  assert.equal(generateRouteTypes({ ...options, check: true }), false);
  assert.equal(readFileSync(destination, "utf8"), source + "// stale\n");
  assert.equal(generateRouteTypes(options), true);
  assert.equal(readFileSync(destination, "utf8"), source);
});

test("generation is deterministic and quotes path literals", () => {
  const first = [
    { path: "z" },
    { path: 'a"quoted' },
    { index: true },
    { path: "z" },
  ];
  assert.equal(renderPathType(first), renderPathType([...first].reverse()));
  assert.ok(renderPathType(first).includes('#"/a\\"quoted"'));
  assert.throws(() => renderPathType([{ path: "*" }]), /No concrete routes/);
});

test("the standalone check runs from an unrelated working directory", (t) => {
  const before = readFileSync(outputPath, "utf8");
  const generator = fileURLToPath(
    new URL("../../generate-route-types.mjs", import.meta.url),
  );
  execFileSync(process.execPath, [generator, "--check"], {
    cwd: temporaryDirectory(t),
  });
  assert.equal(readFileSync(outputPath, "utf8"), before);
});
