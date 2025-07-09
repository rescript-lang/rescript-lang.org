module Sidebar = SidebarLayout.Sidebar

let makeCategories: string => array<Sidebar.Category.t> = version => [
  {
    name: "Overview",
    items: [
      {name: "Introduction", href: `/docs/manual/${version}/api`},
      if version >= "v12.0.0" {
        {name: "Stdlib", href: `/docs/manual/${version}/api/stdlib`}
      } else {
        {name: "Core", href: `/docs/manual/${version}/api/core`}
      },
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
    let router = Next.Router.useRouter()
    let route = router.route

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
