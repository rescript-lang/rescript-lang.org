type loaderData = {
  compiledMdx: CompiledMdx.t,
  title: string,
  description: string,
}

@live
let loader: ReactRouter.Loader.t<loaderData>

@live
let default: unit => React.element
