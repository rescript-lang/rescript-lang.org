type props = {versions: array<string>}

let default = props => {
  let (isOverlayOpen, setOverlayOpen) = React.useState(() => false)

  let lazyPlayground = Next.Dynamic.dynamic(
    async () => await import(Playground.make),
    {
      ssr: false,
      loading: () => <span> {React.string("Loading...")} </span>,
    },
  )

  let playground = React.createElement(lazyPlayground, {versions: props.versions})

  <>
    <Meta
      title="ReScript Playground"
      description="Try ReScript in the browser"
      ogImage="/static/og/try.png"
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
  let versions = {
    let response = await Webapi.Fetch.fetch(
      "https://cdn.rescript-lang.org/playground-bundles/versions.json",
    )
    let json = await Webapi.Fetch.Response.json(response)
    json
    ->JSON.Decode.array
    ->Option.getOrThrow
    ->Array.map(json => json->JSON.Decode.string->Option.getOrThrow)
  }

  {"props": {versions: versions}}
}
