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

let snapshot = async (directory, version, moduleName) => {
  let target = join([directory, version])
  await mkdir(target, {recursive: true})
  let writes = ["stdlib", "belt", "dom"]->Array.map(async library => {
    let modulePath = `${library}/${moduleName->String.toLowerCase}`
    let data = JSON.Object(
      Dict.fromArray([
        (
          modulePath,
          JSON.Object(
            Dict.fromArray([
              ("id", JSON.String(`${library->String.capitalize}.${moduleName}`)),
              ("name", JSON.String(moduleName)),
              ("docstrings", JSON.Array([JSON.String(`Docs from ${version}`)])),
              ("items", JSON.Array([])),
            ]),
          ),
        ),
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
    expect(ApiData.paths(modules))->toStrictEqual([`docs/manual/api/${library}/newmodule`])
    let content = Dict.getUnsafe(modules, `${library}/newmodule`)->JSON.stringify
    expect(content)->toContain("NewModule")
    expect(content)->toContain("Docs from v12.10.0")
  })
})

test("an incomplete newest publication fails instead of mixing snapshot versions", async () => {
  let directory = await temporaryDirectory("api-data-incomplete-")
  await snapshot(directory, "v12.3.0", "OldModule")
  await mkdir(join([directory, "v12.3.1"]), {recursive: true})
  await write(join([directory, "v12.3.1", "stdlib.json"]), "{}")
  expect(() => ApiData.load(~directory, ~major="v12"))->toThrow("belt.json")
})

test("a malformed published library fails during loading", async () => {
  let directory = await temporaryDirectory("api-data-malformed-")
  await snapshot(directory, "v12.3.1", "NewModule")
  await write(join([directory, "v12.3.1", "dom.json"]), "[]")
  expect(() => ApiData.load(~directory, ~major="v12"))->toThrow("expected an object")
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
