type loaderData = {
  compiledMdx: CompiledMdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
