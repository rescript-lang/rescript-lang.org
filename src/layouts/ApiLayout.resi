let allApiVersions: array<(string, string)>

module OldDocsWarning: {
  @react.component
  let make: (~version: string, ~route: Path.t) => React.element
}

let makeBreadcrumbs: (~prefix: Url.breadcrumb, Path.t) => list<Url.breadcrumb>

@react.component
let make: (
  ~breadcrumbs: list<Url.breadcrumb>=?,
  ~categories: array<SidebarLayout.Sidebar.Category.t>,
  ~title: string=?,
  ~version: string=?,
  ~activeToc: TableOfContents.t=?,
  ~children: React.element,
) => React.element
