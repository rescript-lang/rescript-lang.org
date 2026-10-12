@val @scope(("import", "meta")) external url: string = "url"

let run = () => {
  let missing = AlgoliaEnvStatus.getMissingPublicAlgoliaVars(~env=Node.Process.env)
  if Array.length(missing) > 0 {
    Console.warn(AlgoliaEnvStatus.formatDisabledMessage(missing))
  }
}

let isMainModule = () =>
  switch Node.Process.argv[1] {
  | Some(entrypoint) =>
    Node.URL.fileURLToPath(url) === Node.Path.resolve(Node.Process.cwd(), entrypoint)
  | None => false
  }

let _ = if isMainModule() {
  run()
}
