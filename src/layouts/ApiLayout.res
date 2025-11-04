// This is used for the version dropdown in the api layouts
let allApiVersions = Constants.allManualVersions

module Sidebar = SidebarLayout.Sidebar

module OldDocsWarning = {
  @react.component
  let make = (~version: string, ~route: Path.t) => {
    let url = Url.parse((route :> string))
    let latestUrl =
      "/" ++ (Array.join(url.base, "/") ++ ("/latest/" ++ Array.join(url.pagepath, "/")))

    open Markdown

    let label = switch Array.find(allApiVersions, ((v, _)) => {
      v === version
    }) {
    | Some((_, label)) => label
    | None => version
    }

    let additionalText = switch version {
    | "v8.0.0" => "(These docs cover all versions between v3 to v8 and are equivalent to the old BuckleScript docs before the rebrand)"
    | _ => ""
    }

    <div className="mb-10">
      <Info>
        <P>
          {React.string(
            "You are currently looking at the " ++
            (label ++
            " docs (Reason v3.6 syntax edition). You can find the latest API docs "),
          )}
          <A href=latestUrl> {React.string("here")} </A>
          {React.string(".")}
          <p className="text-14 mt-2"> {React.string(additionalText)} </p>
        </P>
      </Info>
    </div>
  }
}

let makeBreadcrumbs = (~prefix: Url.breadcrumb, route: Path.t): list<Url.breadcrumb> => {
  let url = Url.parse((route :> string))

  let (_, rest) = // Strip the "api" part of the url before creating the rest of the breadcrumbs
  Array.slice(url.pagepath, ~start=1)->Array.reduce((prefix.href, []), (acc, path) => {
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
  Array.concat([prefix], rest)->List.fromArray
}

@react.component
let make = (
  ~breadcrumbs=?,
  ~categories: array<Sidebar.Category.t>,
  ~title="",
  ~version: option<string>=?,
  ~activeToc: option<TableOfContents.t>=?,
  ~children,
) => {
  let {pathname: route} = ReactRouter.useLocation()

  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)
  let toggleSidebar = () => setSidebarOpen(prev => !prev)

  React.useEffect(() => {
    // TODO: replicate this for React Router
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
    <div className="flex justify-between text-fire font-medium items-baseline">
      {switch version {
      | Some(version) =>
        let onChange = evt => {
          open Url
          ReactEvent.Form.preventDefault(evt)
          let version = (evt->ReactEvent.Form.target)["value"]
          let url = Url.parse((route :> string))
          WebAPI.Storage.setItem(localStorage, ~key=(Url.Manual :> string), ~value=version)

          let targetUrl =
            "/" ++
            (Array.join(url.base, "/") ++
            ("/" ++ (version ++ ("/" ++ Array.join(url.pagepath, "/")))))
          navigate(targetUrl)
        }
        <VersionSelect />
      | None => React.null
      }}
    </div>

  let sidebar =
    <Sidebar preludeSection isOpen=isSidebarOpen toggle=toggleSidebar categories ?activeToc route />

  let pageTitle = switch breadcrumbs {
  | Some(list{_, {Url.name: name}}) => name
  | Some(list{_, module_, {name}}) => module_.name ++ ("." ++ name)
  | _ => "API"
  }
  <SidebarLayout
    ?breadcrumbs
    // metaTitle={pageTitle ++ " | ReScript API"}
    theme=#Reason
    sidebarState=(isSidebarOpen, setSidebarOpen)
    sidebar
  >
    children
  </SidebarLayout>
}
