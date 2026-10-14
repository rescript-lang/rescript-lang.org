@scope(("process", "env")) external nodeEnv: string = "NODE_ENV"
@scope(("process", "env"))
external playgroundBundleEndpoint: option<string> = "PLAYGROUND_BUNDLE_ENDPOINT"

let cdnBaseUrl = "https://cdn.rescript-lang.org"
let remoteBundleBaseUrl = () => playgroundBundleEndpoint->Option.getOr(cdnBaseUrl)
