type t = {
  bundleBaseUrl: string,
  versions: array<string>,
}

module Env = {
  @scope(("process", "env")) external nodeEnv: string = "NODE_ENV"
  @scope(("process", "env"))
  external playgroundBundleEndpoint: option<string> = "PLAYGROUND_BUNDLE_ENDPOINT"
}

let fetchVersions = async versionsBaseUrl => {
  let response = await fetch(versionsBaseUrl ++ "/playground-bundles/versions.json")
  let json = await WebAPI.Response.json(response)
  json
  ->JSON.Decode.array
  ->Option.getOrThrow
  ->Array.map(json => json->JSON.Decode.string->Option.getOrThrow)
}

let load = async () => {
  let (bundleBaseUrl, versionsBaseUrl) = switch (Env.playgroundBundleEndpoint, Env.nodeEnv) {
  | (Some(baseUrl), _) => (baseUrl, baseUrl)
  | (None, "development") =>
    let baseUrl = "https://cdn.rescript-lang.org"
    (baseUrl, baseUrl)
  | (None, _) =>
    let baseUrl = "https://cdn.rescript-lang.org"
    (baseUrl, baseUrl)
  }

  try {
    let versions = await fetchVersions(versionsBaseUrl)
    Some({
      bundleBaseUrl,
      versions,
    })
  } catch {
  | JsExn(error) =>
    Console.error2("error while fetching guide compiler versions", error)
    None
  }
}
