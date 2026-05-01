module NavItem: {
  type t = {
    name: string,
    href: string,
  }
  @react.component
  let make: (
    ~getActiveToc: t => option<TableOfContents.t>=?,
    ~isHidden: bool=?,
    ~isItemActive: t => bool=?,
    ~items: array<t>,
    ~onClick: unit => unit,
  ) => React.element
}

module Category: {
  type t = {
    name: string,
    items: array<NavItem.t>,
  }

  @react.component
  let make: (
    ~category: t,
    ~getActiveToc: NavItem.t => option<TableOfContents.t>=?,
    ~isItemActive: NavItem.t => bool=?,
    ~onClick: unit => unit,
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
