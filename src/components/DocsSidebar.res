@react.component
let make = (~categories: array<SidebarNav.Category.t>, ~activeToc: option<TableOfContents.t>=?) => {
  let {pathname} = ReactRouter.useLocation()
  let currentRoute = (pathname :> string)->Url.normalizePath

  <aside className="px-4 w-full block">
    <div className="flex justify-between items-baseline">
      <div className="flex flex-col text-fire font-medium">
        <VersionSelect />
      </div>
      <button className="flex items-center" onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}>
        <Icon.Close />
      </button>
    </div>
    <div className="mb-56">
      {categories
      ->Array.map(category => {
        let isItemActive = (navItem: SidebarNav.NavItem.t) =>
          navItem.href->Url.normalizePath === currentRoute
        let getActiveToc = (navItem: SidebarNav.NavItem.t) =>
          if navItem.href->Url.normalizePath === currentRoute {
            activeToc
          } else {
            None
          }
        <div key=category.name>
          <SidebarNav.Category
            isItemActive
            getActiveToc
            category
            onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}
          />
        </div>
      })
      ->React.array}
    </div>
  </aside>
}
