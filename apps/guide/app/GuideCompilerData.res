type t = {bundleBaseUrl: string}

module Env = {
  @scope(("process", "env"))
  external playgroundBundleEndpoint: option<string> = "PLAYGROUND_BUNDLE_ENDPOINT"
}

let load = () => {
  bundleBaseUrl: Env.playgroundBundleEndpoint->Option.getOr("https://cdn.rescript-lang.org"),
}
