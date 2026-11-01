@react.component
let make: (
  ~sidebar: React.element,
  ~rightSidebar: React.element=?,
  ~categories: array<SidebarNav.Category.t>=?,
  ~docSearchLvl0: string=?,
  ~children: React.element,
) => React.element
