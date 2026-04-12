/** Convert Mdx.attributes to sidebar nav items, building hrefs from rootPath + slug. */
let convertToNavItems: (array<Mdx.attributes>, string) => array<SidebarLayout.Sidebar.NavItem.t>

/** Get a single sidebar category by name from a dict of grouped nav items. */
let getGroup: (
  Dict.t<array<SidebarLayout.Sidebar.NavItem.t>>,
  string,
) => SidebarLayout.Sidebar.Category.t

/** Get multiple sidebar categories by name from a dict of grouped nav items. */
let getAllGroups: (
  Dict.t<array<SidebarLayout.Sidebar.NavItem.t>>,
  array<string>,
) => array<SidebarLayout.Sidebar.Category.t>
