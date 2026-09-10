@val @scope(("import", "meta")) external url: string = "url"

let run = () => {
  let missing = AlgoliaEnvStatus.getMissingPublicAlgoliaVars(~env=NodeJs.Process.env)
  if Array.length(missing) > 0 {
    Console.warn(AlgoliaEnvStatus.formatDisabledMessage(missing))
  }
}

let isMainModule = () =>
  switch NodeJs.Process.argv[1] {
  | Some(entrypoint) =>
    NodeJs.URL.fileURLToPath(url) === NodeJs.Path.resolve(NodeJs.Process.cwd(), entrypoint)
  | None => false
  }

let _ = if isMainModule() {
  run()
}
