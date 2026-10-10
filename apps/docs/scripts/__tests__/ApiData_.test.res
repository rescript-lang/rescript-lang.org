open ScriptTest

test("API versions use numeric ordering and stay on the requested compiler major", async () => {
  let versions = [
    "v12.9.99",
    "v12.10.2",
    "v12.10.10",
    "v13.0.0",
    "v12.11.0-alpha.1",
    "v12.20.0-rc.1",
    "latest",
    "v12.30",
    "v12.40.0junk",
  ]
  expect(ApiData.latestVersion(~major="v12", versions))->toBe("v12.10.10")
  expect(ApiData.latestVersion(~major="v13", versions))->toBe("v13.0.0")
})

test("missing published API data fails instead of using another major", async () => {
  expect(() => ApiData.latestVersion(~major="v12", ["v13.0.0", "v12.0.0-rc.5"]))->toThrow(
    "No published API data for v12",
  )
})

let apiModule = (id, name, version) => JSON.Object(
  Dict.fromArray([
    ("id", JSON.String(id)),
    ("name", JSON.String(name)),
    ("docstrings", JSON.Array([JSON.String(`Docs from ${version}`)])),
    ("items", JSON.Array([])),
  ]),
)

let snapshot = async (directory, version, moduleName) => {
  let target = join([directory, version])
  await mkdir(target, {recursive: true})
  let writes = ["stdlib", "belt", "dom"]->Array.map(async library => {
    let modulePath = `${library}/${moduleName->String.toLowerCase}`
    let data = JSON.Object(
      Dict.fromArray([
        (library, apiModule(library->String.capitalize, library->String.capitalize, version)),
        (modulePath, apiModule(`${library->String.capitalize}.${moduleName}`, moduleName, version)),
      ]),
    )
    await write(join([target, `${library}.json`]), JSON.stringify(data))
  })
  let results = await Promise.all(writes)
  ignore(results)
}

test("routes and module content read the same newest published snapshot", async () => {
  let directory = await temporaryDirectory("api-data-")
  await snapshot(directory, "v12.9.0", "OldModule")
  await snapshot(directory, "v12.10.0", "NewModule")
  await snapshot(directory, "v13.0.0", "FutureModule")
  let data = ApiData.load(~directory, ~major="v12")
  expect(data.version)->toBe("v12.10.0")
  ["stdlib", "belt", "dom"]->Array.forEach(library => {
    let modules = ApiData.library(data, library)
    expect(ApiData.paths(modules))->toStrictEqual([
      `docs/manual/api/${library}`,
      `docs/manual/api/${library}/newmodule`,
    ])
    let content = Dict.getUnsafe(modules, `${library}/newmodule`)->JSON.stringify
    expect(content)->toContain("NewModule")
    expect(content)->toContain("Docs from v12.10.0")
  })
})

test("an incomplete newest publication fails instead of mixing snapshot versions", async () => {
  let directory = await temporaryDirectory("api-data-incomplete-")
  await snapshot(directory, "v12.3.0", "OldModule")
  await mkdir(join([directory, "v12.3.1"]), {recursive: true})
  let stdlib = await read(join([directory, "v12.3.0", "stdlib.json"]))
  await write(join([directory, "v12.3.1", "stdlib.json"]), stdlib)
  expect(() => ApiData.load(~directory, ~major="v12"))->toThrow("belt.json")
})

test("a malformed published library fails during loading", async () => {
  let directory = await temporaryDirectory("api-data-malformed-")
  await snapshot(directory, "v12.3.1", "NewModule")
  await write(join([directory, "v12.3.1", "dom.json"]), "[]")
  expect(() => ApiData.load(~directory, ~major="v12"))->toThrow("expected an object")
})

for_(["stdlib", "belt", "dom"])("published %s API requires its root module", async library => {
  let directory = await temporaryDirectory("api-data-root-")
  await snapshot(directory, "v12.3.0", "OldModule")
  await snapshot(directory, "v12.3.1", "NewModule")
  let path = join([directory, "v12.3.1", `${library}.json`])
  // A nonempty library without its root and an empty library must both fail.
  let withoutRoot = JSON.Object(
    Dict.fromArray([
      (`${library}/newmodule`, apiModule(`${library}.NewModule`, "NewModule", "v12.3.1")),
    ]),
  )
  await write(path, JSON.stringify(withoutRoot))
  expect(() => ApiData.load(~directory, ~major="v12"))->toThrow(`missing root module ${library}`)
  await write(path, "{}")
  expect(() => ApiData.load(~directory, ~major="v12"))->toThrow(`missing root module ${library}`)
})

let malformedModules = [
  ("object", JSON.Null),
  ("id", JSON.parseOrThrow(`{"name":"Dom","docstrings":[],"items":[]}`)),
  ("name", JSON.parseOrThrow(`{"id":"Dom","docstrings":[],"items":[]}`)),
  ("docstrings", JSON.parseOrThrow(`{"id":"Dom","name":"Dom","items":[]}`)),
  ("docstrings", JSON.parseOrThrow(`{"id":"Dom","name":"Dom","docstrings":[42],"items":[]}`)),
  ("items", JSON.parseOrThrow(`{"id":"Dom","name":"Dom","docstrings":[]}`)),
]

let malformedCases =
  malformedModules->Array.flatMap(((field, invalid)) =>
    ["dom", "dom/newmodule"]->Array.map(modulePath => (field, modulePath, invalid))
  )

for_(malformedCases)("published modules validate %s in %s", async ((
  field,
  modulePath,
  invalid,
)) => {
  let directory = await temporaryDirectory("api-data-module-")
  await snapshot(directory, "v12.3.1", "NewModule")
  let path = join([directory, "v12.3.1", "dom.json"])
  let modules = Dict.fromArray([
    ("dom", apiModule("Dom", "Dom", "v12.3.1")),
    ("dom/newmodule", apiModule("Dom.NewModule", "NewModule", "v12.3.1")),
  ])
  Dict.set(modules, modulePath, invalid)
  await write(path, modules->JSON.Object->JSON.stringify)
  expect(() => ApiData.load(~directory, ~major="v12"))->toThrow(`invalid module ${modulePath}`)
  expect(() => ApiData.load(~directory, ~major="v12"))->toThrow(field)
})

for_(["stdlib", "belt", "dom"])(
  "published %s API uses the compiler publisher's data",
  async library => {
    let data = ApiData.current()
    expect(data.version->String.startsWith(DocsVersion.current ++ "."))->toBe(true)
    let published = await readJson(join(["../../data/api", data.version, `${library}.json`]))
    expect(ApiData.library(data, library)->JSON.Object)->toStrictEqual(published)
  },
)
