/* let makeBreadcrumbsFromPaths: (~basePath: string, array<string>) => list<Url.breadcrumb> */
let makeBreadcrumbs: (~basePath: string, string) => list<Url.breadcrumb>

@react.component
let make: (
  ~breadcrumbs: list<Url.breadcrumb>=?,
  ~metaTitleCategory: string, // e.g. Introduction | My Meta Title Category
  ~frontmatter: JSON.t=?,
  ~version: string=?,
  ~availableVersions: array<(string, string)>=?,
  ~nextVersion: (string, string)=?,
  ~activeToc: SidebarLayout.Toc.t=?,
  ~categories: array<SidebarLayout.Sidebar.Category.t>,
  ~components: MarkdownComponents.t=?,
  ~theme: ColorTheme.t=?,
  ~children: React.element,
) => React.element

module type StaticContent = {
  /* let categories: array<SidebarLayout.Sidebar.Category.t>; */
  let tocData: SidebarLayout.Toc.raw
}

module Make: (Content: StaticContent) =>
{
  @react.component
  let make: (
    ~breadcrumbs: list<Url.breadcrumb>=?,
    ~metaTitleCategory: string,
    ~frontmatter: JSON.t=?,
    ~version: string=?,
    ~availableVersions: array<(string, string)>=?,
    ~nextVersion: (string, string)=?,
    /* ~activeToc: option<SidebarLayout.Toc.t>=?, */
    ~components: MarkdownComponents.t=?,
    ~theme: ColorTheme.t=?,
    ~children: React.element,
  ) => React.element
}
