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
  let make = (~children) => {
    let {pathname: route} = ReactRouter.useLocation()

    let breadcrumbs = list{
      {Url.name: "Docs", href: `/docs/manual/introduction`},
      {name: "API", href: `/docs/manual/api`},
    }

    let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)

    let preludeSection =
      <div className="flex flex-col justify-between text-fire font-medium items-baseline">
        <VersionSelect />
      </div>

    let sidebar =
      <Sidebar
        isOpen=isSidebarOpen
        toggle={() => setSidebarOpen(prev => !prev)}
        preludeSection
        categories
        route
      />

    <SidebarLayout
      breadcrumbs
      categories
      metaTitle="API"
      sidebarState=(isSidebarOpen, setSidebarOpen)
      theme={#Js}
      sidebar
    >
      children
    </SidebarLayout>
  }
}
