open ScriptTest
open ApiDataFixtures

let contentDirectory = async directory => {
  let directory = join([directory, "markdown-pages"])
  let writes = [
    "blog",
    "community",
    "docs/manual",
    "docs/guides",
    "docs/react",
    "syntax-lookup",
  ]->Array.map(async name => {
    await mkdir(join([directory, name]), {recursive: true})
  })
  ignore(await Promise.all(writes))
  await write(join([directory, "docs/manual/api.mdx"]), "# API")
  await write(join([directory, "docs/manual/new-page.mdx"]), "# New page")
  directory
}

test(
  "v13 routes and content select the same publication without crossing compiler majors",
  async () => {
    expect(DocsVersion.current)->toBe("v13")
    let directory = await temporaryDirectory("v13-api-routes-")
    let contentDirectory = await contentDirectory(directory)
    let apiDirectory = join([directory, "data/api"])
    await snapshot(apiDirectory, "v12.99.0", "MaintenanceModule")
    await snapshot(apiDirectory, "v13.9.0", "OldModule")
    await snapshot(apiDirectory, "v13.10.0", "NewModule")
    await snapshot(apiDirectory, "v14.0.0", "FutureModule")
    let selected = ApiDataSource.directory(~options={directory: apiDirectory})
    let data = ApiData.load(~directory=apiDirectory, ~major=DocsVersion.current)
    expect(selected)->toBe(join([apiDirectory, data.version]))
    let {routes} = DocsRouteConfig.loadRoutes(~options={contentDirectory, apiDirectory: selected})
    let paths = DocsRouteConfig.concretePaths(routes)
    expect(paths->Array.includes("/docs/manual/new-page"))->toBe(true)
    ["stdlib", "belt", "dom"]->Array.forEach(library => {
      expect(paths->Array.includes(`/docs/manual/api/${library}`))->toBe(true)
      expect(paths->Array.includes(`/docs/manual/api/${library}/newmodule`))->toBe(true)
      expect(paths->Array.includes(`/docs/manual/api/${library}/oldmodule`))->toBe(false)
      expect(paths->Array.includes(`/docs/manual/api/${library}/maintenancemodule`))->toBe(false)
      expect(paths->Array.includes(`/docs/manual/api/${library}/futuremodule`))->toBe(false)
    })
  },
)

test("route types include nested index routes and omit URL patterns", async () => {
  let routes: array<DocsRouteConfig.route> = [
    {
      path: "docs",
      children: [{index: true}, {path: "guide"}, {path: ":slug"}, {path: "*"}, {path: "/try"}],
    },
    {path: "optional?"},
  ]
  expect(DocsRouteConfig.concretePaths(routes))->toStrictEqual(["/docs", "/docs/guide", "/try"])
})

test("route generation detects stale types without overwriting them in check mode", async () => {
  let directory = await temporaryDirectory("v13-route-types-")
  let destination = join([directory, "Path.res"])
  let routes: array<DocsRouteConfig.route> = [{path: "/new-api-module"}]
  await write(destination, "stale")
  expect(DocsRouteConfig.generate(~options={routes, destination, check: true}))->toBe(false)
  expect(await read(destination))->toBe("stale")
  expect(DocsRouteConfig.generate(~options={routes, destination}))->toBe(true)
  expect(await read(destination))->toBe(DocsRouteConfig.renderPathType(routes))
  expect(DocsRouteConfig.generate(~options={routes, destination, check: true}))->toBe(true)
})

test(
  "route generation checks the live v13 configuration from another working directory",
  async () => {
    let directory = await temporaryDirectory("v13-route-cwd-")
    let script = join([cwd(), "generate-route-types.mjs"])
    let result = spawn(
      executable,
      [script, "--check"],
      {
        cwd: directory,
        env: environment,
        encoding: "utf8",
      },
    )
    expectSuccess(result)
  },
)

for_(
  [
    "stdlib",
    "stdlib/array",
    "belt",
    "belt/array",
    "dom",
    "dom/storage",
  ]->Array.flatMap(modulePath =>
    ["", ".data", "/_.data", "/"]->Array.map(suffix => (modulePath, suffix))
  ),
)("API loader serves the published v13 %s%s module and its sidebar", async ((
  modulePath,
  suffix,
)) => {
  let request = WebAPI.Request.fromURL(
    `https://v13.rescript-lang.org/docs/manual/api/${modulePath}${suffix}`,
  )
  let result = await ApiRoute.loader({request: request})
  switch result {
  | Error(message) => expect(message)->toBe("expected a valid published API module")
  | Ok({module_, toctree}) =>
    let library = modulePath->String.split("/")->Array.getUnsafe(0)
    let published = ApiData.current()->ApiData.library(library)->Dict.getUnsafe(modulePath)
    let published = published->JSON.Decode.object->Option.getOrThrow
    expect(module_.id)->toBe(published->Dict.getUnsafe("id")->JSON.Decode.string->Option.getOrThrow)
    expect(module_.docstrings)->toStrictEqual(
      published
      ->Dict.getUnsafe("docstrings")
      ->JSON.Decode.array
      ->Option.getOrThrow
      ->Array.map(value => value->JSON.Decode.string->Option.getOrThrow),
    )
    expect(toctree.name)->toBe(library->String.capitalize)
    expect(toctree.children->Array.length > 0)->toBe(true)
  }
})

for_(["", ".data", "/_.data", "/"])(
  "MDX loaders resolve document and data URLs consistently: %s",
  async suffix => {
    expect(
      MdxFile.resolveFilePath(
        `/docs/manual/introduction${suffix}`,
        ~dir="markdown-pages/docs/manual",
        ~alias="docs/manual",
      ),
    )->toBe("markdown-pages/docs/manual/introduction.mdx")
  },
)
