type loaderData = LandingPage.highlightedExample

let loader: ReactRouter.Loader.t<loaderData> = async _ => {
  let {res, js} = LandingPage.playgroundExample
  let highlightedExample: LandingPage.highlightedExample = {
    res: ShikiHighlighter.highlight(~code=res, ~language="rescript"),
    js: ShikiHighlighter.highlight(~code=js, ~language="javascript"),
  }
  highlightedExample
}

let default = () => {
  let highlightedExample = ReactRouter.useLoaderData()
  <>
    <LandingPage highlightedExample />
  </>
}
