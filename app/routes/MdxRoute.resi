type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  blogPost?: BlogApi.post,
  resources?: array<CommunityContent.link>,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
