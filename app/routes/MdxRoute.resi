open ReactRouter

type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
}

let loader: ReactRouter.Loader.t<loaderData>
let default: unit => Jsx.element
