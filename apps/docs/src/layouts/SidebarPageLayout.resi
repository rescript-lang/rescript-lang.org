@react.component
let make: (
  // (Sidebar, toggleSidebar) ... for toggling sidebar in mobile view
  ~sidebarState: (bool, (bool => bool) => unit)=?,
  ~sidebar: React.element,
  ~rightSidebar: React.element=?,
  ~categories: array<SidebarNav.Category.t>=?,
  ~docSearchLvl0: string=?,
  ~children: React.element,
) => React.element
