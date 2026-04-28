let categories: array<SidebarLayout.Sidebar.Category.t>

type loaderData = {
  compiledMdx: CompiledMdx.t,
  title: string,
  description: string,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
