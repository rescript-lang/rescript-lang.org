type loaderData = {
  compiledMdx: CompiledMdx.t,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
  categories: array<SidebarNav.Category.t>,
}

@live
let loader: ReactRouter.Loader.t<loaderData>

@live
let default: unit => React.element
