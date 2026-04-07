let filterByPath = (entries: array<MdxFile.sidebarEntry>, path) =>
  Array.filter(entries, entry =>
    entry.path->Option.map(String.includes(_, path))->Option.getOr(false)
  )

let sortByOrder = (entries: array<MdxFile.sidebarEntry>) =>
  Array.toSorted(entries, (a, b) =>
    switch (a.order, b.order) {
    | (Some(a), Some(b)) => a > b ? 1.0 : -1.0
    | _ => -1.0
    }
  )

let groupBySection = (entries: array<MdxFile.sidebarEntry>) =>
  Array.reduce(entries, (Dict.make() :> Dict.t<array<MdxFile.sidebarEntry>>), (acc, item) => {
    let section = item.section->Option.flatMap(Dict.get(acc, _))
    switch section {
    | Some(section) => section->Array.push(item)
    | None => item.section->Option.forEach(section => acc->Dict.set(section, [item]))
    }
    acc
  })

let convertToNavItems = (items: array<MdxFile.sidebarEntry>, rootPath) =>
  Array.map(items, (item): SidebarLayout.Sidebar.NavItem.t => {
    let href = switch item.slug {
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
