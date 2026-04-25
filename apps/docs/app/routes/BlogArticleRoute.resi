type loaderData = {
  compiledMdx: CompiledMdx.t,
  blogPost: BlogApi.post,
  title: string,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
