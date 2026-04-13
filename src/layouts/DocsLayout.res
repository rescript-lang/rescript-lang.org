// This module is used for all plain prose text related
// Docs, mostly /docs/manual and similar sections

module Sidebar = SidebarLayout.Sidebar

@react.component
let make = (
  ~activeToc: option<TableOfContents.t>=?,
  ~breadcrumbs: option<list<Url.breadcrumb>>=?,
  ~categories: array<Sidebar.Category.t>,
  ~components=MarkdownComponents.default,
  ~editHref: option<string>=?,
  ~theme=#Reason,
  ~children,
) => {
  let {pathname: route} = ReactRouter.useLocation()

  let currentRoute = (route :> string)->Url.normalizePath

  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)
  let toggleSidebar = () => setSidebarOpen(prev => !prev)

  let preludeSection =
    <div className="flex flex-col justify-between text-fire font-medium items-baseline">
      <VersionSelect />
    </div>

  let sidebar =
    <Sidebar isOpen=isSidebarOpen toggle=toggleSidebar preludeSection ?activeToc categories route />

  let mobileSidebar = if Array.length(categories) > 0 {
    Some(
      <aside className="px-4 w-full block">
        <div className="flex justify-between items-baseline">
          <div className="flex flex-col text-fire font-medium">
            <VersionSelect />
          </div>
          <button
            className="flex items-center" onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}
          >
            <Icon.Close />
          </button>
        </div>
        <div className="mb-56">
          {categories
          ->Array.map(category => {
            let isItemActive = (navItem: Sidebar.NavItem.t) =>
              navItem.href->Url.normalizePath === currentRoute
            let getActiveToc = (navItem: Sidebar.NavItem.t) =>
              if navItem.href->Url.normalizePath === currentRoute {
                activeToc
              } else {
                None
              }
            <div key=category.name>
              <Sidebar.Category
                isItemActive
                getActiveToc
                category
                onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}
              />
            </div>
          })
          ->React.array}
        </div>
      </aside>,
    )
  } else {
    None
  }

  <>
    <NavbarTertiary sidebar=?mobileSidebar>
      {switch breadcrumbs {
      | Some(crumbs) => <SidebarLayout.BreadCrumbs crumbs />
      | None => React.null
      }}
      {switch editHref {
      | Some(href) =>
        <a href className="inline text-14 hover:underline text-fire" rel="noopener noreferrer">
          {React.string("Edit")}
        </a>
      | None => React.null
      }}
    </NavbarTertiary>
    <SidebarLayout theme sidebarState=(isSidebarOpen, setSidebarOpen) sidebar categories>
      children
    </SidebarLayout>
  </>
}
