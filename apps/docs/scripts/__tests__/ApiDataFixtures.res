open ScriptTest

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
