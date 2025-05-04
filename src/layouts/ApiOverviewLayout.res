module Sidebar = SidebarLayout.Sidebar

let makeCategories: string => array<Sidebar.Category.t> = version => [
  {
    name: "",
    items: [
      {name: "Overview", href: `/docs/manual/${version}/api`},
      {name: "Core", href: `/docs/manual/${version}/api/core`},
      {name: "Syntax Lookup", href: "/syntax-lookup"},
    ],
  },
  {
    name: "Additional Libraries",
    items: [
      {name: "Belt", href: `/docs/manual/${version}/api/belt`},
      {name: "Dom", href: `/docs/manual/${version}/api/dom`},
    ],
  },
]

/* Used for API docs (structured data) */
module Docs = {
  @react.component
  let make = (~version, ~components=ApiMarkdown.default, ~children) => {
    let title = "API"
    let categories = makeCategories(version)

    <ApiLayout title categories version components> children </ApiLayout>
  }
}
