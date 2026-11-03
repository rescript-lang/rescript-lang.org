@module("../../styles/playground.css?url")
external playgroundCss: string = "default"

type stylesheet = {rel: string, href: string}

let links = () => [{rel: "stylesheet", href: playgroundCss}]

type props = CompilerData.t

let loader = () => CompilerData.load(~location=SameOriginInProduction)

module ClientOnly = {
  @react.component
  let make = (~bundleBaseUrl, ~versions) => {
    <React.Suspense fallback={<div className="h-full bg-gray-100  min-h-screen" />}>
      <PlaygroundLazy bundleBaseUrl versions />
    </React.Suspense>
  }
}

let default = () => {
  let data: option<props> = ReactRouter.useLoaderData()
  <>
    <Meta
      title="ReScript Playground" description="Try ReScript in the browser" ogImage="/og/try.avif"
    />

    {switch data {
    | Some({bundleBaseUrl, versions}) => <ClientOnly bundleBaseUrl versions />
    | None =>
      <div className="mt-16 p-5 text-xl text-red-500 self-center">
        <h1> {React.string("Oops an error occurred!")} </h1>
        {React.string("The playground cannot be loaded, please try again in a few moments.")}
      </div>
    }}
  </>
}
