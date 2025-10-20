type props = {
  bundleBaseUrl: string,
  versions: array<string>,
}

let loader = async () => {
  let (bundleBaseUrl, versionsBaseUrl) = switch (
    Node.Process.Env.playgroundBundleEndpoint,
    Node.Process.Env.nodeEnv,
  ) {
  | (Some(baseUrl), _) => (baseUrl, baseUrl)
  | (None, "development") => {
      // Use remote bundles in dev
      let baseUrl = "https://cdn.rescript-lang.org"
      (baseUrl, baseUrl)
    }
  | (None, _) => (
      // Use same-origin requests for the bundle
      "/playground-bundles",
      // There is no version endpoint in the build phase
      "https://cdn.rescript-lang.org",
    )
  }

  let versions = {
    let response = await fetch(versionsBaseUrl + "/playground-bundles/versions.json")
    let json = await WebAPI.Response.json(response)
    json
    ->JSON.Decode.array
    ->Option.getOrThrow
    ->Array.map(json => json->JSON.Decode.string->Option.getOrThrow)
  }

  {
    bundleBaseUrl,
    versions,
  }
}

module ClientOnly = {
  @react.component
  let make = (~bundleBaseUrl, ~versions) => {
    <React.Suspense fallback={<div className="h-full bg-gray-100  min-h-screen" />}>
      <LazyPlayground bundleBaseUrl versions />
    </React.Suspense>
  }
}

let default = () => {
  let {bundleBaseUrl, versions} = ReactRouter.useLoaderData()

  <ClientOnly bundleBaseUrl versions />
}
