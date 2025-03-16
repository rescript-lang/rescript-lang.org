/***
Generate docs from ReScript Compiler

## Run

```bash
node scripts/gendocs.mjs path/to/rescript-compiler path/to/rescript-core/src/RescriptCore.res version forceReWrite
```

## Examples

```bash
node scripts/gendocs.mjs path/to/rescript-compiler latest true
```
*/
@val @scope(("import", "meta")) external url: string = "url"

open Node
module Docgen = RescriptTools.Docgen

let args = Process.argv->Array.sliceToEnd(~start=2)
let dirname =
  url
  ->URL.fileURLToPath
  ->Path.dirname

let compilerLibPath = switch args->Array.get(0) {
| Some(path) => Path.join([path, "jscomp", "others"])
| None => failwith("First argument should be path to rescript-compiler repo")
}

let corePath = switch args->Array.get(1) {
| Some(path) => path
| _ => failwith("Second argument should be path to rescript-core/src/RescriptCore.res")
}

let version = switch args->Array.get(2) {
| Some(version) => version
| None => failwith("Third argument should be a version, `latest`, `v10`")
}

let forceReWrite = switch args->Array.get(3) {
| Some("true") => true
| _ => false
}

let dirVersion = Path.join([dirname, "..", "data", "api", version])

if Fs.existsSync(dirVersion) {
  Console.error(`Directory ${dirVersion} already exists`)
  if !forceReWrite {
    Process.exit(1)
  }
} else {
  Fs.mkdirSync(dirVersion)
}

let entryPointFiles = ["js.ml", "belt.res", "dom.res"]

let hiddenModules = ["Js.Internal", "Js.MapperRt"]

type module_ = {
  id: string,
  docstrings: array<string>,
  name: string,
  items: array<Docgen.item>,
}

type section = {
  name: string,
  docstrings: array<string>,
  deprecated: option<string>,
  topLevelItems: array<Docgen.item>,
  submodules: array<module_>,
}

let env = Process.env

let docsDecoded = entryPointFiles->Array.map(libFile => {
  let entryPointFile = Path.join2(compilerLibPath, libFile)

  Dict.set(env, "FROM_COMPILER", "true")

  let output =
    ChildProcess.execSync(
      `./node_modules/.bin/rescript-tools doc ${entryPointFile}`,
    )->Buffer.toString

  output
  ->JSON.parseExn
  ->Docgen.decodeFromJson
})

let coreDocs = {
  Dict.set(env, "FROM_COMPILER", "false")

  let output =
    ChildProcess.execSync(`./node_modules/.bin/rescript-tools doc ${corePath}`)->Buffer.toString

  output
  ->JSON.parseExn
  ->Docgen.decodeFromJson
}

let docsDecoded = Array.concat(docsDecoded, [coreDocs])

let docs = docsDecoded->Array.map(doc => {
  let topLevelItems = doc.items->Array.filterMap(item =>
    switch item {
    | Value(_) as item | Type(_) as item => item->Some
    | _ => None
    }
  )

  let rec getModules = (lst: list<Docgen.item>, moduleNames: list<module_>) =>
    switch lst {
    | list{
        Module({id, items, name, docstrings})
        | ModuleAlias({id, items, name, docstrings})
        | ModuleType({id, items, name, docstrings}),
        ...rest,
      } =>
      if Array.includes(hiddenModules, id) {
        getModules(rest, moduleNames)
      } else {
        let id = String.startsWith(id, "RescriptCore")
          ? String.replace(id, "RescriptCore", "Core")
          : id
        getModules(
          list{...rest, ...List.fromArray(items)},
          list{{id, items, name, docstrings}, ...moduleNames},
        )
      }
    | list{Type(_) | Value(_), ...rest} => getModules(rest, moduleNames)
    | list{} => moduleNames
    }

  let id = String.startsWith(doc.name, "RescriptCore")
    ? String.replace(doc.name, "RescriptCore", "Core")
    : doc.name

  let top = {id, name: id, docstrings: doc.docstrings, items: topLevelItems}
  let submodules = getModules(doc.items->List.fromArray, list{})->List.toArray
  let result = [top]->Array.concat(submodules)

  (id, result)
})

let allModules = {
  open JSON
  let encodeItem = (docItem: Docgen.item) => {
    switch docItem {
    | Value({id, name, docstrings, signature, ?deprecated}) => {
        let id = String.startsWith(id, "RescriptCore")
          ? String.replace(id, "RescriptCore", "Core")
          : id
        let dict = Dict.fromArray(
          [
            ("id", id->String),
            ("kind", "value"->String),
            ("name", name->String),
            (
              "docstrings",
              docstrings
              ->Array.map(s => s->String)
              ->Array,
            ),
            ("signature", signature->String),
          ]->Array.concat(
            switch deprecated {
            | Some(v) => [("deprecated", v->String)]
            | None => []
            },
          ),
        )
        dict->Object->Some
      }

    | Type({id, name, docstrings, signature, ?deprecated}) =>
      let id = String.startsWith(id, "RescriptCore")
        ? String.replace(id, "RescriptCore", "Core")
        : id
      let dict = Dict.fromArray(
        [
          ("id", id->String),
          ("kind", "type"->String),
          ("name", name->String),
          ("docstrings", docstrings->Array.map(s => s->String)->Array),
          ("signature", signature->String),
        ]->Array.concat(
          switch deprecated {
          | Some(v) => [("deprecated", v->String)]
          | None => []
          },
        ),
      )
      Object(dict)->Some

    | _ => None
    }
  }

  docs->Array.map(((topLevelName, modules)) => {
    let submodules =
      modules
      ->Array.map(mod => {
        let items =
          mod.items
          ->Array.filterMap(item => encodeItem(item))
          ->Array

        let id = String.startsWith(mod.id, "RescriptCore") ? "Core" : mod.id

        let rest = Dict.fromArray([
          ("id", id->String),
          ("name", mod.name->String),
          ("docstrings", mod.docstrings->Array.map(s => s->String)->Array),
          ("items", items),
        ])
        (
          mod.id
          ->String.split(".")
          ->Array.join("/")
          ->String.toLowerCase,
          rest->Object,
        )
      })
      ->Dict.fromArray

    (topLevelName, submodules)
  })
}

let () = {
  allModules->Array.forEach(((topLevelName, mod)) => {
    let json = JSON.Object(mod)

    let topLevelName = String.startsWith(topLevelName, "RescriptCore") ? "Core" : topLevelName

    Fs.writeFileSync(
      Path.join([dirVersion, `${topLevelName->String.toLowerCase}.json`]),
      json->JSON.stringify(~space=2),
    )
  })
}

type rec node = {
  name: string,
  path: array<string>,
  children: array<node>,
}

// Generate TOC modules
let () = {
  let joinPath = (~path: array<string>, ~name: string) => {
    Array.concat(path, [name])->Array.map(path => path->String.toLowerCase)
  }
  let rec getModules = (lst: list<Docgen.item>, moduleNames, path) => {
    switch lst {
    | list{
        Module({id, items, name}) | ModuleAlias({id, items, name}) | ModuleType({id, items, name}),
        ...rest,
      } =>
      if Array.includes(hiddenModules, id) {
        getModules(rest, moduleNames, path)
      } else {
        let itemsList = items->List.fromArray
        let children = getModules(itemsList, [], joinPath(~path, ~name))

        getModules(
          rest,
          Array.concat([{name, path: joinPath(~path, ~name), children}], moduleNames),
          path,
        )
      }
    | list{Type(_) | Value(_), ...rest} => getModules(rest, moduleNames, path)
    | list{} => moduleNames
    }
  }

  let tocTree = docsDecoded->Array.map(({name, items}) => {
    let name = String.startsWith(name, "RescriptCore") ? "Core" : name
    let path = name->String.toLowerCase
    (
      path,
      {
        name,
        path: [path],
        children: items
        ->List.fromArray
        ->getModules([], [path]),
      },
    )
  })

  Fs.writeFileSync(
    Path.join([dirVersion, "toc_tree.json"]),
    tocTree
    ->Dict.fromArray
    ->JSON.stringifyAny
    ->Option.getExn,
  )
}
