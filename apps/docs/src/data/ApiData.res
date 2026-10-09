type t = {
  version: string,
  stdlib: Dict.t<JSON.t>,
  belt: Dict.t<JSON.t>,
  dom: Dict.t<JSON.t>,
}

// Plain Node scripts use the same version selection as the ReScript loaders.
let latestVersion = ApiDataSource.latestVersion

let load = (~directory, ~major) => {
  let version = latestVersion(~major, Node.Fs.readdirSync(directory))
  let readLibrary = name => {
    let path = Node.Path.join([directory, version, `${name}.json`])
    switch Node.Fs.readFileSync2(path, "utf-8")->JSON.parseOrThrow {
    | Object(modules) => modules
    | _ => JsError.throwWithMessage(`Invalid API data in ${path}: expected an object`)
    }
  }
  {version, stdlib: readLibrary("stdlib"), belt: readLibrary("belt"), dom: readLibrary("dom")}
}

// Load on demand: route modules also enter the runtime SSR bundle for /try.
let current = {
  let cached = ref(None)
  () => {
    switch cached.contents {
    | Some(data) => data
    | None =>
      let data = load(~directory="../../data/api", ~major=DocsVersion.current)
      cached.contents = Some(data)
      data
    }
  }
}

let library = (data, name) =>
  switch name {
  | "belt" => data.belt
  | "dom" => data.dom
  | _ => data.stdlib
  }

let paths = modules => modules->Dict.keysToArray->Array.map(path => "docs/manual/api/" ++ path)
