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

  try {
    let versions = {
      let response = await fetch(versionsBaseUrl + "/playground-bundles/versions.json")
      let json = await WebAPI.Response.json(response)
      json
      ->JSON.Decode.array
      ->Option.getOrThrow
      ->Array.map(json => json->JSON.Decode.string->Option.getOrThrow)
    }

    Some({
      bundleBaseUrl,
      versions,
    })
  } catch {
  | JsExn(e) =>
    Console.error2("error while fetching compiler versions", e)
    None
  }
}
module ClientOnly = {
  @react.component
  let make = (~bundleBaseUrl, ~versions) => {
    <React.Suspense fallback={<div className="h-full bg-gray-100  min-h-screen" />}>
      <PlaygroundLazy bundleBaseUrl versions />
    </React.Suspense>
  }
}

let default = () => {
  let data = ReactRouter.useLoaderData()
  <>
    <Meta
      title="ReScript Playground" description="Try ReScript in the browser" ogImage="/og/try.avif"
    />

    {switch data {
    | Some({bundleBaseUrl, versions}) => <ClientOnly bundleBaseUrl versions />
    | None =>
      <div className="text-xl text-red-500 self-center">
        <h1> {React.string("Oops an error occurred!")} </h1>
        {React.string("The playground cannot be loaded, please try again in a few moments.")}
      </div>
    }}
  </>
}
