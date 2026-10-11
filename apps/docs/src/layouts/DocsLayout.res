// This module is used for all plain prose text related
// Docs, mostly /docs/manual and similar sections

module Sidebar = SidebarNav

@react.component
let make = (
  ~activeToc: option<TableOfContents.t>=?,
  ~categories: array<Sidebar.Category.t>,
  ~components=MarkdownComponents.default,
  ~docSearchLvl0=?,
  ~children,
) => {
  let {pathname: route} = ReactRouter.useLocation()

  let preludeSection =
    <div className="flex flex-col justify-between text-fire font-medium items-baseline">
      <VersionSelect />
    </div>

  let sidebar =
    <Sidebar isOpen=false toggle={() => ()} preludeSection ?activeToc categories route />

  <SidebarPageLayout sidebar categories ?docSearchLvl0> children </SidebarPageLayout>
}
