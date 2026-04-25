type loaderData = {
  compiledMdx: CompiledMdx.t,
  mdxSources: array<SyntaxLookup.item>,
  activeSyntaxItem: option<SyntaxLookup.item>,
  title: string,
  description: string,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
