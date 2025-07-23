let allApiVersions: array<(string, string)>

module OldDocsWarning: {
  @react.component
  let make: (~version: string, ~route: string) => React.element
}

let makeBreadcrumbs: (~prefix: Url.breadcrumb, string) => list<Url.breadcrumb>

@react.component
let make: (
  ~breadcrumbs: list<Url.breadcrumb>=?,
  ~categories: array<SidebarLayout.Sidebar.Category.t>,
  ~title: string=?,
  ~version: string=?,
  ~activeToc: SidebarLayout.Toc.t=?,
  ~components: MarkdownComponents.t=?,
  ~children: React.element,
) => React.element
