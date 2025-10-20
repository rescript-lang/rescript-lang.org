type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  blogPost?: BlogApi.post,
  mdxSources?: array<SyntaxLookup.item>,
  activeSyntaxItem?: SyntaxLookup.item,
  breadcrumbs?: list<Url.breadcrumb>,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
