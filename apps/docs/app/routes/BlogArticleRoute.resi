type loaderData = {
  compiledMdx: CompiledMdx.t,
  blogPost: BlogApi.post,
  title: string,
}

@live
let loader: ReactRouter.Loader.t<loaderData>

@live
let default: unit => React.element
