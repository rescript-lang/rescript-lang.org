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
  ~activeToc: option<TableOfContents.t>=?,
  ~categories: array<Category.t>,
  ~components=MarkdownComponents.default,
  ~theme=#Reason,
  ~children,
) => {
  let {pathname: route} = ReactRouter.useLocation()

  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)
  let toggleSidebar = () => setSidebarOpen(prev => !prev)

  let preludeSection =
    <div className="flex flex-col justify-between text-fire font-medium items-baseline">
      <VersionSelect />
    </div>

  let sidebar =
    <Sidebar isOpen=isSidebarOpen toggle=toggleSidebar preludeSection ?activeToc categories route />

  <SidebarLayout theme sidebarState=(isSidebarOpen, setSidebarOpen) sidebar categories>
    children
  </SidebarLayout>
}

module type StaticContent = {
  /* let categories: array<SidebarLayout.Sidebar.Category.t>; */
  let tocData: SidebarLayout.Toc.raw
}
