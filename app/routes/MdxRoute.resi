type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  blogPost?: BlogApi.post,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
