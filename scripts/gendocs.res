/***
Generate docs from ReScript Compiler

## Run

```bash
node scripts/gendocs.mjs path/to/rescript-monorepo version forceReWrite
```

## Examples

```bash
node scripts/gendocs.mjs path/to/rescript-monorepo latest true
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
| Some(path) => Path.join([path, "runtime"])
| None => failwith("First argument should be path to rescript-compiler repo")
}

let version = switch args->Array.get(1) {
| Some(version) => version
| None => failwith("Second argument should be a version, `latest`, `v10`")
}

let forceReWrite = switch args->Array.get(2) {
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

let entryPointFiles = ["Belt.res", "Dom.res", "Js.res", "Stdlib.res"]

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

let docsDecoded = entryPointFiles->Array.map(libFile =>
  try {
    let entryPointFile = Path.join2(compilerLibPath, libFile)

    Dict.set(env, "FROM_COMPILER", "false")

    let output = ChildProcess.execSync(
      `./node_modules/.bin/rescript-tools doc ${entryPointFile}`,
      ~options={
        maxBuffer: 30_000_000.,
      },
    )->Buffer.toString

    output
    ->JSON.parseExn
    ->Docgen.decodeFromJson
  } catch {
  | Exn.Error(error) =>
    Console.error(
      `Error while generating docs from ${libFile}: ${error
        ->Error.message
        ->Option.getOr("[no message]")}`,
    )
    Error.raise(error)
  }
)

let removeStdlibOrPrimitive = s => s->String.replaceAllRegExp(/Stdlib_|Primitive_js_extern\./g, "")

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
        getModules(
          list{...rest, ...List.fromArray(items)},
          list{{id, items, name, docstrings}, ...moduleNames},
        )
      }
    | list{Type(_) | Value(_), ...rest} => getModules(rest, moduleNames)
    | list{} => moduleNames
    }

  let id = doc.name

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
        let dict = Dict.fromArray(
          [
            ("id", id->String),
            ("kind", "value"->String),
            ("name", name->String),
            (
              "docstrings",
              docstrings
              ->Array.map(s => s->removeStdlibOrPrimitive->String)
              ->Array,
            ),
            (
              "signature",
              signature
              ->removeStdlibOrPrimitive
              ->String,
            ),
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
      let dict = Dict.fromArray(
        [
          ("id", id->String),
          ("kind", "type"->String),
          ("name", name->String),
          ("docstrings", docstrings->Array.map(s => s->removeStdlibOrPrimitive->String)->Array),
          ("signature", signature->removeStdlibOrPrimitive->String),
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

        let rest = Dict.fromArray([
          ("id", mod.id->String),
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
