// This module is used for all plain prose text related
// Docs, mostly /docs/manual/latest and similar sections

module Sidebar = SidebarLayout.Sidebar

module NavItem = Sidebar.NavItem
module Category = Sidebar.Category

/*
let makeBreadcrumbsFromPaths = (~basePath: string, paths: array<string>): list<Url.breadcrumb> => {
  let (_, rest) = Belt.Array.reduce(paths, (basePath, []), (acc, path) => {
    let (baseHref, ret) = acc

    let href = baseHref ++ ("/" ++ path)

    Js.Array2.push(
      ret,
      {
        open Url
        {name: prettyString(path), href: href}
      },
    )->ignore
    (href, ret)
  })
  rest->Belt.List.fromArray
}
*/

let makeBreadcrumbs = (~basePath: string, route: string): list<Url.breadcrumb> => {
  let url = route->Url.parse

  let (_, rest) = url.pagepath->Array.reduce((basePath, []), (acc, path) => {
    let (baseHref, ret) = acc

    let href = baseHref ++ ("/" ++ path)

    Array.push(
      ret,
      {
        open Url
        {name: prettyString(path), href}
      },
    )->ignore
    (href, ret)
  })
  rest->List.fromArray
}

@react.component
let make = (
  ~activeToc: option<TableOfContents.t>=?,
  ~breadcrumbs: option<list<Url.breadcrumb>>=?,
  ~metaTitleCategory: string, // e.g. Introduction | My Meta Title Category
  ~frontmatter=?,
  ~version: option<string>=?,
  ~availableVersions: option<array<(string, string)>>=?,
  ~nextVersion: option<(string, string)>=?,
  ~categories: array<Category.t>,
  ~components=MarkdownComponents.default,
  ~theme=#Reason,
  ~children,
) => {
  let {pathname: route} = ReactRouter.useLocation()

  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)
  let toggleSidebar = () => setSidebarOpen(prev => !prev)

  React.useEffect(() => {
    // TODO: make this work for React Router
    // open Next.Router.Events
    // let {Next.Router.events: events} = router
    // let onChangeComplete = _url => setSidebarOpen(_ => false)
    // events->on(#routeChangeComplete(onChangeComplete))
    // events->on(#hashChangeComplete(onChangeComplete))
    // Some(
    //   () => {
    //     events->off(#routeChangeComplete(onChangeComplete))
    //     events->off(#hashChangeComplete(onChangeComplete))
    //   },
    // )
    None
  }, [])

  let navigate = ReactRouter.useNavigate()

  let preludeSection =
    <div className="flex flex-col justify-between text-fire font-medium items-baseline">
      {switch version {
      | Some(version) =>
        switch availableVersions {
        | Some(availableVersions) =>
          let onChange = evt => {
            open Url
            ReactEvent.Form.preventDefault(evt)
            let version = (evt->ReactEvent.Form.target)["value"]
            let url = Url.parse((route :> string))
            WebAPI.Storage.setItem(
              localStorage,
              ~key=switch metaTitleCategory {
              | "React" => (React :> string)
              | _ => (Manual :> string)
              },
              ~value=version,
            )

            let targetUrl =
              "/" ++
              (Array.join(url.base, "/") ++
              ("/" ++ (version ++ ("/" ++ Array.join(url.pagepath, "/")))))
            navigate(targetUrl)
          }
          <VersionSelect version={"v12"} availableVersions=["v12", "pre v12"] />
        | None => <span className="font-mono text-14"> {React.string(version)} </span>
        }
      | None => React.null
      }}
    </div>

  let sidebar =
    <Sidebar isOpen=isSidebarOpen toggle=toggleSidebar preludeSection ?activeToc categories route />

  let metaTitle = metaTitleCategory ++ (" | " ++ "ReScript Documentation")

  let (metaElement, editHref) = switch frontmatter {
  | Some(frontmatter) =>
    switch DocFrontmatter.decode(frontmatter) {
    | Some(fm) =>
      let canonical = Null.toOption(fm.canonical)
      let description = Null.toOption(fm.description)
      let title = {
        // We will prefer an existing metaTitle over just a title
        let metaTitle = switch Null.toOption(fm.metaTitle) {
        | Some(metaTitle) => metaTitle
        | None => fm.title
        }
        metaTitle ++ (" | " ++ metaTitleCategory)
      }
      let meta =
        <Meta title ?description ?canonical /* version=Url.parse(router.route).version */ />

      let ghEditHref = switch canonical {
      | Some(canonical) =>
        `https://github.com/rescript-lang/rescript-lang.org/blob/master/pages${canonical}.mdx`->Some
      | None => None
      }
      (meta, ghEditHref)
    | None => (React.null, None)
    }
  | None => (React.null, None)
  }

  <SidebarLayout
    metaTitle
    theme
    components
    sidebarState=(isSidebarOpen, setSidebarOpen)
    sidebar
    categories
    ?breadcrumbs
    ?editHref
  >
    metaElement
    children
  </SidebarLayout>
}

module type StaticContent = {
  /* let categories: array<SidebarLayout.Sidebar.Category.t>; */
  let tocData: SidebarLayout.Toc.raw
}

module Make = (Content: StaticContent) => {
  @react.component
  let make = (
    // base breadcrumbs without the very last element (the currently shown document)
    ~breadcrumbs: option<list<Url.breadcrumb>>=?,
    ~metaTitleCategory: string,
    ~frontmatter=?,
    ~version: option<string>=?,
    ~availableVersions: option<array<(string, string)>>=?,
    ~nextVersion: option<(string, string)>=?,
    ~components: option<MarkdownComponents.t>=?,
    ~theme: option<ColorTheme.t>=?,
    ~children: React.element,
  ) => {
    // TODO RR7 - make this work for React Router

    // let router = Next.Router.useRouter()
    // let route = router.route

    // Extend breadcrumbs with document title
    // let breadcrumbs = Dict.get(Content.tocData, route)->Option.mapOr(breadcrumbs, data => {
    //   let title = data["title"]

    //   Option.map(breadcrumbs, bc => List.concat(bc, list{{Url.name: title, href: route}}))
    // })

    let {toc} = TableOfContents.Context.useTocContext()

    let activeToc = toc

    let categories = {
      let groups = Dict.toArray(Content.tocData)->Array.reduce(Dict.make(), (acc, next) => {
        let (_, value) = next
        switch Nullable.toOption(value["category"]) {
        | Some(category) =>
          switch acc->Dict.get(category) {
          | None => acc->Dict.set(category, [next])
          | Some(arr) =>
            Array.push(arr, next)->ignore
            acc->Dict.set(category, arr)
          }
        | None => Console.log2("has NO category", next)
        }
        acc
      })
      Dict.toArray(groups)->Array.map(((name, values)) => {
        open Category
        {
          name,
          items: Array.map(values, ((href, value)) => {
            // TODO: this probably doesn't work as expected
            NavItem.name: value["title"],
            href: ((value["headers"]->Array.getUnsafe(0))["href"] :> string),
          }),
        }
      })
    }

    make({
      ?breadcrumbs,
      metaTitleCategory,
      ?frontmatter,
      ?version,
      ?availableVersions,
      ?nextVersion,
      categories,
      ?components,
      ?theme,
      children,
    })
  }
}
