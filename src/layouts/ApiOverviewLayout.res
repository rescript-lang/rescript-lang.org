module Sidebar = SidebarLayout.Sidebar

let makeCategories: string => array<Sidebar.Category.t> = version => [
  {
    name: "Overview",
    items: [
      {name: "Introduction", href: #"docs/manual/api"},
      {name: "Stdlib", href: #"docs/manual/api/stdlib"},
    ],
  },
  {
    name: "Additional Libraries",
    items: [
      {name: "Belt", href: #"docs/manual/api/belt"},
      {name: "Dom", href: #"docs/manual/api/dom"},
    ],
  },
]

/* Used for API docs (structured data) */
module Docs = {
  @react.component
  let make = (~version, ~components=ApiMarkdown.default, ~children) => {
    let {pathname: route} = ReactRouter.useLocation()

    let categories = makeCategories(version)

    let breadcrumbs = list{
      {Url.name: "Docs", href: `/docs/manual/${version}/introduction`},
      {name: "API", href: `/docs/manual/${version}/api`},
    }

    <ApiLayout breadcrumbs categories version components>
      {switch version {
      | "v9.0.0" | "v8.0.0" => <ApiLayout.OldDocsWarning route version />
      | _ => React.null
      }}
      children
    </ApiLayout>
  }
}
