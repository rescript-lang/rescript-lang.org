let convertToNavItems = (items, rootPath) =>
  Array.map(items, (item): SidebarLayout.Sidebar.NavItem.t => {
    let href = switch item.Mdx.slug {
    | Some(slug) => `${rootPath}/${slug}`
    | None => rootPath
    }
    {
      name: item.title,
      href,
    }
  })

let getGroup = (groups, groupName): SidebarLayout.Sidebar.Category.t => {
  {
    name: groupName,
    items: groups
    ->Dict.get(groupName)
    ->Option.getOr([]),
  }
}

let getAllGroups = (groups, groupNames): array<SidebarLayout.Sidebar.Category.t> =>
  groupNames->Array.map(item => getGroup(groups, item))
