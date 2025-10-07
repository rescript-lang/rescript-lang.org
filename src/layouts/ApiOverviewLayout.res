module Sidebar = SidebarLayout.Sidebar

// TODO RR7 - do I need this?
let categories: array<Sidebar.Category.t> = [
  {
    name: "Overview",
    items: [
      {name: "Introduction", href: "/docs/manual/api"},
      {name: "Stdlib", href: "/docs/manual/api/stdlib"},
    ],
  },
  {
    name: "Additional Libraries",
    items: [
      {name: "Belt", href: "/docs/manual/api/belt"},
      {name: "Dom", href: "/docs/manual/api/dom"},
    ],
  },
]

/* Used for API docs (structured data) */
module Docs = {
  @react.component
  let make = (~components=ApiMarkdown.default, ~children) => {
    let {pathname: route} = ReactRouter.useLocation()

    let breadcrumbs = list{
      {Url.name: "Docs", href: `/docs/manual/introduction`},
      {name: "API", href: `/docs/manual/api`},
    }

    <ApiLayout breadcrumbs categories components> children </ApiLayout>
  }
}
