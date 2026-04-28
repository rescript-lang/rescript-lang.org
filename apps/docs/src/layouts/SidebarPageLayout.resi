@react.component
let make: (
  ~theme: ColorTheme.t,
  // (Sidebar, toggleSidebar) ... for toggling sidebar in mobile view
  ~sidebarState: (bool, (bool => bool) => unit)=?,
  ~sidebar: React.element,
  ~rightSidebar: React.element=?,
  ~categories: array<SidebarNav.Category.t>=?,
  ~children: React.element,
) => React.element
