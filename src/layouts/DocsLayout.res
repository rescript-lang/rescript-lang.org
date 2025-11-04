// This module is used for all plain prose text related
// Docs, mostly /docs/manual and similar sections

module Sidebar = SidebarLayout.Sidebar

module NavItem = Sidebar.NavItem
module Category = Sidebar.Category

let makeBreadcrumbs = (~basePath: string, route: string): list<Url.breadcrumb> => {
  let url = route->Url.parse

  let (_, rest) = url.pagepath->Array.reduce((basePath, []), (acc, path) => {
    let (baseHref, ret) = acc

    let href = baseHref ++ ("/" ++ path)

    Array.push(
      ret,
      {
        open Url
        {name: prettyString(path), href}
      },
    )->ignore
    (href, ret)
  })
  rest->List.fromArray
}

@react.component
let make = (
  ~editHref: option<string>=?,
  ~activeToc: option<TableOfContents.t>=?,
  ~breadcrumbs: option<list<Url.breadcrumb>>=?,
  ~frontmatter=?,
  ~version: option<string>=?,
  ~availableVersions: option<array<(string, string)>>=?,
  ~nextVersion: option<(string, string)>=?,
  ~categories: array<Category.t>,
  ~components=MarkdownComponents.default,
  ~theme=#Reason,
  ~children,
) => {
  let {pathname: route} = ReactRouter.useLocation()

  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)
  let toggleSidebar = () => setSidebarOpen(prev => !prev)

  let navigate = ReactRouter.useNavigate()

  let preludeSection =
    <div className="flex flex-col justify-between text-fire font-medium items-baseline">
      <VersionSelect />
    </div>

  let sidebar =
    <Sidebar isOpen=isSidebarOpen toggle=toggleSidebar preludeSection ?activeToc categories route />

  <SidebarLayout
    theme sidebarState=(isSidebarOpen, setSidebarOpen) sidebar categories ?breadcrumbs ?editHref
  >
    children
  </SidebarLayout>
}

module type StaticContent = {
  /* let categories: array<SidebarLayout.Sidebar.Category.t>; */
  let tocData: SidebarLayout.Toc.raw
}

module Make = (Content: StaticContent) => {
  @react.component
  let make = (
    // base breadcrumbs without the very last element (the currently shown document)
    ~breadcrumbs: option<list<Url.breadcrumb>>=?,
    ~frontmatter=?,
    ~version: option<string>=?,
    ~availableVersions: option<array<(string, string)>>=?,
    ~nextVersion: option<(string, string)>=?,
    ~components: option<MarkdownComponents.t>=?,
    ~theme: option<ColorTheme.t>=?,
    ~children: React.element,
  ) => {
    let {toc} = TableOfContents.Context.useTocContext()

    let activeToc = toc

    let categories = {
      let groups = Dict.toArray(Content.tocData)->Array.reduce(Dict.make(), (acc, next) => {
        let (_, value) = next
        switch Nullable.toOption(value["category"]) {
        | Some(category) =>
          switch acc->Dict.get(category) {
          | None => acc->Dict.set(category, [next])
          | Some(arr) =>
            Array.push(arr, next)->ignore
            acc->Dict.set(category, arr)
          }
        | None => Console.log2("has NO category", next)
        }
        acc
      })
      Dict.toArray(groups)->Array.map(((name, values)) => {
        open Category
        {
          name,
          items: Array.map(values, ((href, value)) => {
            // TODO: this probably doesn't work as expected
            NavItem.name: value["title"],
            href: ((value["headers"]->Array.getUnsafe(0))["href"] :> string),
          }),
        }
      })
    }

    make({
      ?breadcrumbs,
      frontmatter,
      ?version,
      ?availableVersions,
      ?nextVersion,
      categories,
      ?components,
      ?theme,
      children,
    })
  }
}
