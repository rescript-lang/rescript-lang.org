let convertToNavItems = (items, rootPath) =>
  Array.map(items, (item): SidebarNav.NavItem.t => {
    let href = switch item.Mdx.slug {
    | Some(slug) => `${rootPath}/${slug}`
    | None => rootPath
    }
    {
      name: item.title,
      href,
    }
  })

let getGroup = (groups, groupName): SidebarNav.Category.t => {
  {
    name: groupName,
    items: groups
    ->Dict.get(groupName)
    ->Option.getOr([]),
  }
}

let getAllGroups = (groups, groupNames): array<SidebarNav.Category.t> =>
  groupNames->Array.map(item => getGroup(groups, item))
