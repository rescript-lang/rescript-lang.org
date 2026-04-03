type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  mdxSources?: array<SyntaxLookup.item>,
  activeSyntaxItem?: SyntaxLookup.item,
  breadcrumbs?: list<Url.breadcrumb>,
  title: string,
  filePath: option<string>,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
