module Sidebar = SidebarLayout.Sidebar

let makeCategories: Url.t => array<Sidebar.Category.t> = url => {
  switch url.version {
  | Version("v12.0.0" | "v11.0.0") | Latest | Next =>
    let version = Url.getVersionString(url)
    [
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
  | _ => throw(Failure(`Invalid version ${url->Url.getVersionString}`))
  }
}

/* Used for API docs (structured data) */
module Docs = {
  @react.component
  let make = (~version, ~components=ApiMarkdown.default, ~children) => {
    let router = Next.Router.useRouter()
    let route = router.route

    let categories = makeCategories(version)
    let versionStr = Url.getVersionString(version)

    <ApiLayout categories version=versionStr components>
      {switch version.version {
      | Version("v9.0.0" | "v8.0.0") => <ApiLayout.OldDocsWarning route version=versionStr />
      | _ => React.null
      }}
      children
    </ApiLayout>
  }
}
