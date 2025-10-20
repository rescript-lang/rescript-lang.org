module Toc: {
  // the plain data coming from the toc file
  type raw = Dict.t<{
    "title": string,
    "category": Nullable.t<string>,
    "headers": array<{
      "name": string,
      "href": Path.t,
    }>,
  }>
}

module Sidebar: {
  module NavItem: {
    type t = {
      name: string,
      href: string,
    }
    @react.component
    let make: (
      ~getActiveToc: t => option<TableOfContents.t>=?,
      ~isItemActive: t => bool=?,
      ~isHidden: bool=?,
      ~items: array<t>,
    ) => React.element
  }
  module Category: {
    type t = {
      name: string,
      items: array<NavItem.t>,
    }

    @react.component
    let make: (
      ~getActiveToc: NavItem.t => option<TableOfContents.t>=?,
      ~isItemActive: NavItem.t => bool=?,
      ~category: t,
    ) => React.element
  }

  @react.component
  let make: (
    ~categories: array<Category.t>,
    ~route: Path.t,
    ~toplevelNav: React.element=?,
    ~title: string=?,
    ~preludeSection: React.element=?,
    ~activeToc: TableOfContents.t=?,
    ~isOpen: bool,
    ~toggle: unit => unit,
  ) => React.element
}

@react.component
let make: (
  ~metaTitle: string,
  ~theme: ColorTheme.t,
  ~editHref: string=?,
  // (Sidebar, toggleSidebar) ... for toggling sidebar in mobile view
  ~sidebarState: (bool, (bool => bool) => unit),
  ~sidebar: React.element,
  ~rightSidebar: React.element=?,
  ~categories: array<Sidebar.Category.t>=?,
  ~breadcrumbs: list<Url.breadcrumb>=?,
  ~children: React.element,
) => React.element
