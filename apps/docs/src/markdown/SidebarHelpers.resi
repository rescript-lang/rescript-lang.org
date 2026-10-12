/** Convert Mdx.attributes to sidebar nav items, building hrefs from rootPath + slug. */
let convertToNavItems: (array<Mdx.attributes>, string) => array<SidebarNav.NavItem.t>

/** Get a single sidebar category by name from a dict of grouped nav items. */
let getGroup: (Dict.t<array<SidebarNav.NavItem.t>>, string) => SidebarNav.Category.t

/** Get multiple sidebar categories by name from a dict of grouped nav items. */
let getAllGroups: (
  Dict.t<array<SidebarNav.NavItem.t>>,
  array<string>,
) => array<SidebarNav.Category.t>
