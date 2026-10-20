type loaderData = {
  compiledMdx: CompiledMdx.t,
  mdxSources: array<SyntaxLookup.item>,
  activeSyntaxItem: option<SyntaxLookup.item>,
  title: string,
  description: string,
}

@live
let loader: ReactRouter.Loader.t<loaderData>

@live
let default: unit => React.element
