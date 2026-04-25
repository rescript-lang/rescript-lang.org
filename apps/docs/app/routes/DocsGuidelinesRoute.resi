type loaderData = {
  compiledMdx: CompiledMdx.t,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
