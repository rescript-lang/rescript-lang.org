// This module is used for all plain prose text related
// Docs, mostly /docs/manual and similar sections

module Sidebar = SidebarLayout.Sidebar

@react.component
let make = (
  ~activeToc: option<TableOfContents.t>=?,
  ~categories: array<Sidebar.Category.t>,
  ~components=MarkdownComponents.default,
  ~docSearchLvl0=?,
  ~theme=#Reason,
  ~children,
) => {
  let {pathname: route} = ReactRouter.useLocation()

  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)
  let toggleSidebar = () => setSidebarOpen(prev => !prev)

  let preludeSection =
    <div className="flex flex-col justify-between text-fire font-medium items-baseline">
      <VersionSelect />
    </div>

  let sidebar =
    <Sidebar isOpen=isSidebarOpen toggle=toggleSidebar preludeSection ?activeToc categories route />

  <SidebarLayout
    theme sidebarState=(isSidebarOpen, setSidebarOpen) sidebar categories ?docSearchLvl0
  >
    children
  </SidebarLayout>
}
