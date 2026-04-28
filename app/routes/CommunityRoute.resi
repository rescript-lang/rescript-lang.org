type loaderData = {
  compiledMdx: CompiledMdx.t,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
  categories: array<SidebarNav.Category.t>,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
