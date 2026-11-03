type t = {bundleBaseUrl: string, versions: array<string>}
type endpoints = {bundleBaseUrl: string, versionsBaseUrl: string}
type bundleLocation = Remote | SameOriginInProduction

let cdnBaseUrl = CompilerEnvironment.cdnBaseUrl

let endpoints = (~location, ~nodeEnv, ~override) =>
  switch override {
  | Some(baseUrl) => {bundleBaseUrl: baseUrl, versionsBaseUrl: baseUrl}
  | None => {
      bundleBaseUrl: location === SameOriginInProduction && nodeEnv !== "development"
        ? "/playground-bundles"
        : cdnBaseUrl,
      versionsBaseUrl: cdnBaseUrl,
    }
  }

let configuredEndpoints = location =>
  endpoints(
    ~location,
    ~nodeEnv=CompilerEnvironment.nodeEnv,
    ~override=CompilerEnvironment.playgroundBundleEndpoint,
  )

let fetchVersions = async versionsBaseUrl => {
  let response = await fetch(versionsBaseUrl ++ "/playground-bundles/versions.json")
  if response.ok === false {
    JsError.throwWithMessage(
      `Could not fetch compiler versions from ${versionsBaseUrl}: HTTP ${response.status->Int.toString}`,
    )
  }
  let json = await response->WebAPI.Response.json
  json
  ->JSON.Decode.array
  ->Option.getOrThrow
  ->Array.map(json => json->JSON.Decode.string->Option.getOrThrow)
}

let load = async (~location) => {
  let {bundleBaseUrl, versionsBaseUrl} = configuredEndpoints(location)
  try {
    let versions = await fetchVersions(versionsBaseUrl)
    Some({bundleBaseUrl, versions})
  } catch {
  | JsExn(error) =>
    Console.error2("error while fetching compiler versions", error)
    None
  }
}
