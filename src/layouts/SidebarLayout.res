/*
    This is the master layout for displaying sidebar based API docs.
    Most of the modules defined in here are here to be reused
    in other API related layouts, such as the Markdown representation
    or the Sidebar component.
 */
module Link = ReactRouter.Link

let isDocRoute = (~route: Path.t) => {
  let route = (route :> string)
  route->String.includes("/docs/") || route->String.includes("/syntax-lookup")
}

module Toc = {
  type raw = Dict.t<{
    "title": string,
    "category": Nullable.t<string>,
    "headers": array<{
      "name": string,
      "href": Path.t,
    }>,
  }>

  @react.component
  let make = (~entries: array<TableOfContents.entry>, ~onClick) =>
    <ul className="mt-3 py-1 mb-4 border-l border-fire-10">
      {Array.map(entries, ({header, href}) => {
        <li key=header className="pl-2 mt-2 first:mt-1" dataTestId=header>
          <Link.String
            prefetch={#intent}
            onClick={evt => {
              evt->ReactEvent.Mouse.preventDefault
              WebAPI.Document.getElementById(
                document,
                href->String.replace("#", ""),
              )->WebAPI.Element.scrollIntoView_alignToTop
              onClick()
            }}
            to={"#" ++ href->Url.normalizeAnchor}
            className="font-normal block text-14 text-gray-40 leading-tight hover:text-gray-80"
            preventScrollReset=true
          >
            {React.string(
              header
              ->String.replaceRegExp(/<[^>]+>/g, "")
              ->String.replaceRegExp(/([\r\n]+ +)+/g, ""),
            )}
          </Link.String>
        </li>
      })->React.array}
    </ul>
}

module Sidebar = {
  module Title = {
    @react.component
    let make = (~children) => {
      let className = "hl-overline text-gray-80 mt-5" //overline

      <div className> children </div>
    }
  }

  module NavItem = {
    // Navigation point information
    type t = {
      name: string,
      href: string,
    }
    @react.component
    let make = (
      ~getActiveToc: option<t => option<TableOfContents.t>>=?,
      ~isHidden=false,
      ~isItemActive: t => bool=_nav => false,
      ~items: array<t>,
      ~onClick,
    ) =>
      <ul className="mt-2 text-14 font-medium">
        {Array.map(items, m => {
          let hidden = isHidden ? "hidden" : "block"
          let active = isItemActive(m)
            ? ` bg-fire-5 text-red-500 leading-5 pl-2 font-medium block hover:bg-fire-70 `
            : ""

          let activeToc = switch getActiveToc {
          | Some(getActiveToc) => getActiveToc(m)
          | None => None
          }

          <li key=m.name className={hidden ++ " mt-1 leading-4"}>
            <Link.String
              to=m.href
              prefetch={#intent}
              className={"block py-1 md:h-auto tracking-tight text-gray-60 rounded-sm hover:bg-gray-20" ++
              active}
            >
              {React.string(m.name)}
            </Link.String>
            {switch activeToc {
            | Some({entries}) =>
              if Array.length(entries) === 0 {
                React.null
              } else {
                <Toc entries onClick />
              }
            | None => React.null
            }}
          </li>
        })->React.array}
      </ul>
  }

  module Category = {
    type t = {
      name: string,
      items: array<NavItem.t>,
    }

    @react.component
    let make = (
      ~category: t,
      ~getActiveToc=?,
      ~isItemActive: option<NavItem.t => bool>=?,
      ~onClick,
    ) =>
      <div key=category.name className="my-10">
        <Title> {React.string(category.name)} </Title>
        <NavItem ?isItemActive ?getActiveToc items=category.items onClick />
      </div>
  }

  // subitems: list of functions inside given module (defined by route)
  @react.component
  let make = (
    ~categories: array<Category.t>,
    ~route: Path.t,
    ~toplevelNav=React.null,
    ~title as _: option<string>=?,
    ~preludeSection=React.null,
    ~activeToc: option<TableOfContents.t>=?,
    ~isOpen: bool,
    ~toggle: unit => unit,
  ) => {
    let isItemActive = (navItem: NavItem.t) => navItem.href === (route :> string)

    let getActiveToc = (navItem: NavItem.t) => {
      if navItem.href === (route :> string) {
        activeToc
      } else {
        None
      }
    }

    // the height of the navbars above is fluid across pages, and it's easy to get it wrong
    // so we calculate it dynamically here
    let sidebarTopOffset = isOpen
      ? {
          let mobileNavbarHeight =
            Nullable.make(document->WebAPI.Document.getElementById("mobile-navbar"))
            ->Nullable.map(el => el.clientHeight)
            ->Nullable.getOr(0)
          let docNavbarHeight =
            Nullable.make(document->WebAPI.Document.getElementById("doc-navbar"))
            ->Nullable.map(el => el.clientHeight)
            ->Nullable.getOr(0)
          let mainNavbarHeight =
            Nullable.make(document->WebAPI.Document.getElementById("main-navbar"))
            ->Nullable.map(el => el.clientHeight)
            ->Nullable.getOr(0)

          mobileNavbarHeight + docNavbarHeight + mainNavbarHeight
        }
      : 0

    // If a user changes screen size we want to close the sidebar
    React.useEffect(() => {
      let handleResize = () => {
        if isOpen {
          toggle()
        }
      }

      addEventListener(Resize, handleResize)
      Some(() => removeEventListener(Resize, handleResize))
    }, [isOpen])

    <>
      <div
        id="sidebar"
        style={{
          top: isOpen ? `${sidebarTopOffset->Int.toString}px` : "0px",
        }}
        className={(
          isOpen ? "fixed left-0 h-full w-full" : "hidden"
        ) ++ " z-20  min-w-3xs md:max-w-3xs lg:max-w-xs md:block h-auto md:relative overflow-y-visible px-4 md:pl-0 pt-2 bg-white md:mt-0 border-r border-gray-20"}
      >
        <aside
          id="sidebar-content"
          className="h-full relative top-0 block md:top-28 md:sticky overflow-y-auto pb-24 max-h-[calc(100vh-7rem)] px-4"
        >
          <button
            style={{
              // This is needed to make sure it's clickable
              zIndex: "20",
            }}
            onClick={evt => {
              ReactEvent.Mouse.preventDefault(evt)
              Console.debug("Sidebar toggle")
              toggle()
            }}
            className="md:hidden h-16 flex pt-2 right-4 absolute cursor-pointer"
          >
            <Icon.Close />
          </button>
          <div className="flex justify-between" dataTestId="sidebar-toplevel-nav">
            <div className="w-3/4 md:w-full"> toplevelNav </div>
          </div>

          preludeSection

          /* Firefox ignores padding in scroll containers, so we need margin
               to make a bottom gap for the sidebar.
               See https://stackoverflow.com/questions/29986977/firefox-ignores-padding-when-using-overflowscroll
 */
          <div className="mb-56">
            {categories
            ->Array.map(category => {
              <div key=category.name>
                <Category getActiveToc isItemActive category onClick=toggle />
              </div>
            })
            ->React.array}
          </div>
        </aside>
      </div>
    </>
  }
}

module BreadCrumbs = {
  @react.component
  let make = (~crumbs: list<Url.breadcrumb>) => {
    let {pathname} = ReactRouter.useLocation()

    let lastSegment =
      (pathname :> string)
      ->String.split("/")
      ->Array.filter(segment =>
        segment !== "docs" &&
        segment !== "manual" &&
        segment !== "react" &&
        segment !== "api" &&
        segment !== ""
      )
      ->Array.last

    let crumbs = switch lastSegment {
    | Some(lastSegment) =>
      crumbs->List.concat(list{
        {Url.name: lastSegment->String.capitalize, href: (pathname :> string)},
      })
    | None => crumbs
    }

    <div className="w-full captions overflow-x-auto text-gray-60">
      {List.mapWithIndex(crumbs, (crumb, i) => {
        let item = if i === List.length(crumbs) - 1 {
          <span key={Int.toString(i)}> {React.string(crumb.name)} </span>
        } else {
          <Link.String key={Int.toString(i)} to=crumb.href prefetch={#intent}>
            {React.string(crumb.name)}
          </Link.String>
        }
        if i > 0 {
          <span key={Int.toString(i)}>
            {React.string(" / ")}
            item
          </span>
        } else {
          item
        }
      })
      ->List.toArray
      ->React.array}
    </div>
  }
}

module MobileDrawerButton = {
  @react.component
  let make = (~hidden: bool, ~onClick) =>
    <button className={(hidden ? "hidden " : "") ++ "md:hidden mr-3"} onClick=onClick>
      <img className="h-4" src="/ic_sidebar_drawer.svg" />
    </button>
}

@react.component
let make = (
  ~theme: ColorTheme.t,
  ~editHref: option<string>=?,
  ~sidebarState: (bool, (bool => bool) => unit),
  // (Sidebar, toggleSidebar) ... for toggling sidebar in mobile view
  ~sidebar: React.element,
  ~rightSidebar: option<React.element>=?,
  ~categories: option<array<Sidebar.Category.t>>=?,
  ~breadcrumbs: option<list<Url.breadcrumb>>=?,
  ~children,
) => {
  let (isNavOpen, setNavOpen) = React.useState(() => false)

  let location = ReactRouter.useLocation()

  let theme = ColorTheme.toCN(theme)

  let hasBreadcrumbs = switch breadcrumbs {
  | None => false
  | Some(l) => List.length(l) > 0
  }

  let breadcrumbs = breadcrumbs->Option.mapOr(React.null, crumbs => <BreadCrumbs crumbs />)

  // TODO: post rr7 - this can most likely be removed
  let (_isSidebarOpen, setSidebarOpen) = sidebarState
  let (_isLocked, toggleScrollLock) = ScrollLockContext.useScrollLock()

  let toggleSidebar = () => {
    setSidebarOpen(prev => !prev)
    toggleScrollLock(prev => !prev)
  }

  let {pathname} = ReactRouter.useLocation()

  React.useEffect(() => {
    setSidebarOpen(_ => false)
    setNavOpen(_ => false)
    None
  }, [pathname])

  let handleDrawerButtonClick = React.useCallback(evt => {
    ReactEvent.Mouse.preventDefault(evt)
    Console.debug("drawer button clicked")
    toggleSidebar()
  }, [])

  let editLinkEl = switch editHref {
  | Some(href) =>
    <a href className="inline text-14 hover:underline text-fire" rel="noopener noreferrer">
      {React.string("Edit")}
    </a>
  | None => React.null
  }

  let pagination = switch categories {
  | Some(categories) =>
    let items = categories->Array.flatMap(c => c.items)

    switch items->Array.findIndex(item => item.href === (location.pathname :> string)) {
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
  <>
    <div
      className={"mt-16 min-w-320 grid max-w-1280 md:mt-32 grid-cols-[auto_minmax(0px,1fr)] pr-4 lg:pr-24 m-auto " ++
      theme}
    >
      sidebar
      <main className="px-4 md:pt-4 lg:px-4 lg:pl-16 lg:mr-8 mb-32 max-w-svw">
        // width of the right content part
        <div
          id="mobile-navbar"
          className={`z-10 fixed border-b shadow ${isDocRoute(~route=pathname)
              ? "top-28"
              : "top-16"} left-0 pl-4 bg-white w-full py-4 lg:relative lg:border-none lg:shadow-none lg:p-0 lg:top-auto flex items-center transition duration-300 ease-out group-[.nav-disappear]:-translate-y-64 lg:group-[.nav-disappear]:translate-y-0 z-25`}
        >
          <MobileDrawerButton hidden=isNavOpen onClick={handleDrawerButtonClick} />
          <div
            className="truncate overflow-x-auto touch-scroll flex items-center space-x-4 md:justify-between mr-4 w-full"
          >
            breadcrumbs
            editLinkEl
          </div>
        </div>
        <div
          className={hasBreadcrumbs ? "mt-28 md:mt-10" : "mt-6 md:-mt-4"}
          dataTestId="side-layout-children"
        >
          children
        </div>
        pagination
      </main>
      {switch rightSidebar {
      | Some(ele) => ele
      | None => React.null
      }}
    </div>
    <Footer />
  </>
}
