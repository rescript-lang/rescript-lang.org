module Link = ReactRouter.Link

@react.component
let make = (
  ~theme: ColorTheme.t,
  ~sidebarState: (bool, (bool => bool) => unit)=(false, _ => ()),
  // (Sidebar, toggleSidebar) ... for toggling sidebar in mobile view
  ~sidebar: React.element,
  ~rightSidebar: option<React.element>=?,
  ~categories: option<array<SidebarNav.Category.t>>=?,
  ~children,
) => {
  let location = ReactRouter.useLocation()

  let theme = ColorTheme.toCN(theme)

  let pagination = switch categories {
  | Some(categories) =>
    let items = categories->Array.flatMap(c => c.items)
    let currentPathname = (location.pathname :> string)->Url.normalizePath

    switch items->Array.findIndex(item => item.href->Url.normalizePath === currentPathname) {
    | -1 => React.null
    | i =>
      let previous = switch items->Array.get(i - 1) {
      | Some({name, href}) =>
        <Link.String
          to=href
          prefetch={#intent}
          className={"flex items-center text-fire hover:text-fire-70 border-2 border-red-300 rounded py-1.5 px-3"}
        >
          <Icon.ArrowRight className={"rotate-180 mr-2"} />
          {React.string(name)}
        </Link.String>
      | None => React.null
      }
      let next = switch items->Array.get(i + 1) {
      | Some({name, href}) =>
        <Link.String
          prefetch={#intent}
          to=href
          className={"flex items-center text-fire hover:text-fire-70 ml-auto border-2 border-red-300 rounded py-1.5 px-3"}
        >
          {React.string(name)}
          <Icon.ArrowRight className={"ml-2"} />
        </Link.String>
      | None => React.null
      }
      <div className={"flex justify-between mt-9"}>
        previous
        next
      </div>
    }
  | None => React.null
  }

  <div className={"min-w-320 " ++ theme}>
    <div className="w-full">
      <div className="flex lg:justify-center">
        <div className="flex w-full max-w-1280 md:mx-10 ">
          sidebar
          <main
            dataTestId="side-layout-children"
            className="px-4 w-full pt-4 md:ml-12 lg:mr-8 mb-32 md:max-w-576 lg:max-w-740 md:pt-8"
          >
            children
            pagination
          </main>
          {switch rightSidebar {
          | Some(ele) => ele
          | None => React.null
          }}
        </div>
      </div>
    </div>
    <Footer />
  </div>
}
