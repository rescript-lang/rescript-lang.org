type props = {
  bundleBaseUrl: string,
  versions: array<string>,
}

let default = props => {
  let (isOverlayOpen, setOverlayOpen) = React.useState(() => false)

  let lazyPlayground = Next.Dynamic.dynamic(
    async () => {
      try {
        await import(Playground.make)
      } catch {
      | JsExn(e) =>
        Console.error2("Error loading Playground:", e)
        JsExn.throw(e)
      }
    },
    {
      ssr: false,
      loading: () => <span> {React.string("Loading...")} </span>,
    },
  )

  let playground = React.createElement(
    lazyPlayground,
    {
      bundleBaseUrl: props.bundleBaseUrl,
      versions: props.versions,
    },
  )

  <>
    <Meta
      title="ReScript Playground" description="Try ReScript in the browser" ogImage="/og/try.png"
    />
    <Next.Head>
      <style> {React.string(`body { background-color: #010427; }`)} </style>
    </Next.Head>
    <div className="text-16">
      <div className="text-gray-40 text-14">
        <Navigation fixed=false isOverlayOpen setOverlayOpen />
        playground
      </div>
    </div>
  </>
}

let getStaticProps: Next.GetStaticProps.t<props, _> = async _ => {
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
    "props": {
      bundleBaseUrl,
      versions,
    },
  }
}
