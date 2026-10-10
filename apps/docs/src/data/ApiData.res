type t = {
  version: string,
  stdlib: Dict.t<JSON.t>,
  belt: Dict.t<JSON.t>,
  dom: Dict.t<JSON.t>,
}

// Plain Node scripts use the same version selection as the ReScript loaders.
let latestVersion = ApiDataSource.latestVersion

let validateModule = (path, modulePath, json) => {
  let invalid = expected =>
    JsError.throwWithMessage(
      `Invalid API data in ${path}: invalid module ${modulePath}: ${expected}`,
    )
  switch json {
  | JSON.Object(fields) =>
    ["id", "name"]->Array.forEach(field => {
      switch Dict.get(fields, field) {
      | Some(String(value)) if value !== "" => ()
      | _ => invalid(`expected a nonempty string for ${field}`)
      }
    })
    switch Dict.get(fields, "docstrings") {
    | Some(Array(docstrings))
      if docstrings->Array.every(value =>
        switch value {
        | String(_) => true
        | _ => false
        }
      ) => ()
    | _ => invalid("expected an array of strings for docstrings")
    }
    switch Dict.get(fields, "items") {
    | Some(Array(_)) => ()
    | _ => invalid("expected an array for items")
    }
  | _ => invalid("expected an object")
  }
}

let load = (~directory, ~major) => {
  let version = latestVersion(~major, Node.Fs.readdirSync(directory))
  let readLibrary = name => {
    let path = Node.Path.join([directory, version, `${name}.json`])
    switch Node.Fs.readFileSync2(path, "utf-8")->JSON.parseOrThrow {
    | Object(modules) =>
      // Root routes are explicit, so a missing root would otherwise render a blank page.
      switch Dict.get(modules, name) {
      | None => JsError.throwWithMessage(`Invalid API data in ${path}: missing root module ${name}`)
      | Some(_) => ()
      }
      modules
      ->Dict.toArray
      ->Array.forEach(((modulePath, json)) => validateModule(path, modulePath, json))
      modules
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
