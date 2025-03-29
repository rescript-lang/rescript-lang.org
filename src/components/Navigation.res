module Link = Next.Link

let link = "no-underline block hover:cursor-pointer hover:text-fire-30 text-gray-40 mb-px"
let activeLink = "font-medium text-fire-30 border-b border-fire"

let linkOrActiveLink = (~target, ~route) => target === route ? activeLink : link

let linkOrActiveLinkSubroute = (~target, ~route) =>
  String.startsWith(route, target) ? activeLink : link

let linkOrActiveApiSubroute = (~route) => {
  let url = Url.parse(route)
  switch url.pagepath[0] {
  | Some("api") => activeLink
  | _ => link
  }
}

module CollapsibleLink = {
  // KeepOpen = Menu has been opened and should stay open
  type state =
    | KeepOpen
    | HoverOpen
    | Closed

  @react.component
  let make = (
    ~title: string,
    ~onStateChange: (~id: string, state) => unit,
    ~allowHover=true,
    /* ~allowInteraction=true, */
    ~id: string,
    ~state: state,
    ~active=false,
    ~children,
  ) => {
    let onClick = _evt => {
      /* ReactEvent.Mouse.preventDefault(evt) */
      /* ReactEvent.Mouse.stopPropagation(evt) */

      onStateChange(
        ~id,
        switch state {
        | Closed => KeepOpen
        | HoverOpen => Closed
        | KeepOpen => Closed
        },
      )
    }

    let onMouseEnter = evt => {
      ReactEvent.Mouse.preventDefault(evt)
      if allowHover {
        onStateChange(~id, HoverOpen)
      }
    }

    let isOpen = switch state {
    | Closed => false
    | KeepOpen
    | HoverOpen => true
    }

    <>
      <div className="relative" onMouseEnter>
        <div className="flex items-center">
          <button
            tabIndex={0}
            onClick
            className={(active ? activeLink : link) ++
            (" border-none flex items-center hover:cursor-pointer " ++
            (isOpen ? " text-fire-30" : ""))}>
            <span className={active ? "border-b border-fire" : ""}> {React.string(title)} </span>
          </button>
        </div>
        <div
          className={(
            isOpen ? "flex" : "hidden"
          ) ++ " fixed left-0 overflow-y-scroll overflow-x-hidden border-gray-80 border-gray-40 min-w-320 w-full h-full bg-white sm:overflow-y-auto sm:bg-transparent sm:h-auto sm:justify-center sm:rounded-bl-xl sm:rounded-br-xl sm:shadow"}
          style={ReactDOMStyle.make(~marginTop="1rem", ())}>
          <div className="w-full"> children </div>
        </div>
      </div>
    </>
  }
}

type collapsible = {
  title: string,
  children: React.element,
  isActiveRoute: string => bool,
  href: string,
  state: CollapsibleLink.state,
}

module DocsSection = {
  type item = {
    imgSrc: string,
    title: string,
    description: string,
    href: string,
    isActive: Url.t => bool,
  }

  module LinkCard = {
    @react.component
    let make = (
      ~icon: React.element,
      ~title: string,
      ~description: string,
      ~href: string,
      ~active=false,
    ) => {
      let isAbsolute = Util.Url.isAbsolute(href)
      let content =
        <div
          className={`hover:bg-gray-5 hover:shadow hover:-mx-8 hover:px-8 hover:cursor-pointer active:bg-gray-20 py-4 flex space-x-4 items-start rounded-xl`}>
          icon
          <div>
            <div
              className={`flex items-center text-16 font-medium ${active
                  ? "text-fire"
                  : "text-gray-80"}`}>
              <span> {React.string(title)} </span>
              {if isAbsolute {
                <Icon.ExternalLink className="inline-block ml-2 w-4 h-4" />
              } else {
                React.null
              }}
            </div>
            <div
              className={`block text-14 text-gray-60 ${active ? "text-fire-50" : "text-gray-60"}`}>
              {React.string(description)}
            </div>
          </div>
        </div>

      if isAbsolute {
        <a href rel="noopener noreferrer" className=""> content </a>
      } else {
        <Next.Link href className=""> content </Next.Link>
      }
    }
  }

  @react.component
  let make = () => {
    let router = Next.Router.useRouter()
    let url = router.route->Url.parse

    let (version, setVersion) = React.useState(_ => url->Url.getVersionString)

    let languageManual = Constants.languageManual(version)

    let documentation = [
      {
        imgSrc: "/static/ic_manual@2x.png",
        title: "Language Manual",
        description: "Reference for all language features",
        href: `/docs/manual/${version}/introduction`,
        isActive: url => {
          switch url.fullpath {
          | ["docs", "manual", _, fragment] => fragment !== "typescript-integration"
          | _ => false
          }
        },
      },
      {
        imgSrc: "/static/ic_rescript_react@2x.png",
        title: "ReScript & React",
        description: "First class bindings for ReactJS",
        href: "/docs/react/latest/introduction",
        isActive: url => {
          switch url.base {
          | ["docs", "react"] => true
          | _ => false
          }
        },
      },
      {
        imgSrc: "/static/ic_gentype@2x.png",
        title: "GenType",
        description: "Seamless TypeScript integration",
        href: `/docs/manual/${version}/typescript-integration`,
        isActive: url => {
          switch url.fullpath {
          | ["docs", "manual", _, "typescript-integration"] => true
          | _ => false
          }
        },
      },
      {
        imgSrc: "/static/ic_reanalyze@2x.png",
        title: "Reanalyze",
        description: "Dead Code & Termination analysis",
        href: "https://github.com/rescript-lang/reanalyze",
        isActive: _ => {
          false
        },
      },
    ]

    let languageManualColumn =
      <div className="flex px-4 sm:justify-center border-r border-gray-10 pt-8 pb-10">
        <div>
          <div
            className="text-12 font-medium text-gray-100 tracking-wide uppercase subpixel-antialiased">
            {React.string("Quick Links")}
          </div>
          <div>
            <ul className="space-y-2 ml-2 mt-6">
              {languageManual
              ->Array.map(item => {
                let (text, href) = item

                let linkClass = if router.route === href {
                  "text-fire-50"
                } else {
                  "hover:text-fire-50"
                }

                <li key=text>
                  <span className="text-fire mr-2"> {React.string(`-`)} </span>
                  <Link href className=linkClass> {React.string(text)} </Link>
                </li>
              })
              ->React.array}
            </ul>
          </div>
        </div>
      </div>

    let ecosystemColumn = {
      <div className="flex px-4 sm:h-full sm:justify-center border-r border-gray-10 pt-8">
        <div className="w-full pb-16" style={ReactDOM.Style.make(~maxWidth="19.625rem", ())}>
          <div
            className="text-12 font-medium text-gray-100 tracking-wide uppercase subpixel-antialiased">
            {React.string("Documentation")}
          </div>
          <div>
            <div className="mt-6">
              {Array.map(documentation, item => {
                let {imgSrc, title, href, description, isActive} = item

                let icon = <img style={ReactDOM.Style.make(~width="2.1875rem", ())} src={imgSrc} />
                <LinkCard key={title} icon title href description active={isActive(url)} />
              })->React.array}
            </div>
          </div>
        </div>
      </div>
    }

    let quickReferenceColumn =
      <div className="flex px-4 sm:h-full sm:justify-center pb-12 pt-8 pb-10">
        <div className="w-full" style={ReactDOM.Style.make(~maxWidth="19.625rem", ())}>
          <div
            className="text-12 font-medium text-gray-100 tracking-wide uppercase subpixel-antialiased">
            {React.string("Exploration")}
          </div>
          <div className="mt-6">
            {
              let packageLink = {
                let icon =
                  <div className="w-6 h-6">
                    <img className="w-full" src={"/static/ic_package.svg"} />
                  </div>
                let active = switch url {
                | {base: ["packages"]} => true
                | _ => false
                }

                <LinkCard
                  icon
                  active
                  title="Packages"
                  href="/packages"
                  description="Explore third party libraries and bindings"
                />
              }
              let syntaxLookupLink = {
                let active = switch url {
                | {base: ["syntax-lookup"]} => true
                | _ => false
                }
                let icon =
                  <div className="-mr-2 flex w-6 h-6 justify-center items-center">
                    <img className="w-4 h-4" src="/static/ic_search.svg" />
                  </div>

                <LinkCard
                  icon
                  title="Syntax Lookup"
                  href="/syntax-lookup"
                  description="Discover all syntax constructs"
                  active
                />
              }

              <>
                packageLink
                syntaxLookupLink
              </>
            }
          </div>
        </div>
      </div>

    let onVersionChange = evt => {
      open Url
      ReactEvent.Form.preventDefault(evt)
      let version = (evt->ReactEvent.Form.target)["value"]

      switch url {
      | {base: ["docs", "manual"]} =>
        let targetUrl =
          "/" ++
          (Array.join(url.base, "/") ++
          ("/" ++ (version ++ ("/" ++ Array.join(url.pagepath, "/")))))
        router->Next.Router.push(targetUrl)
      | _ => ()
      }

      setVersion(_ => version)
    }

    <div
      className="relative w-full bg-white pb-32 min-h-full sm:pb-0 text-gray-60 text-14 rounded-bl-xl rounded-br-xl">
      <div className={"flex justify-center w-full py-2 border-b border-gray-10"}>
        <div className="px-4 w-full space-x-2 max-w-1280 ">
          <VersionSelect
            availableVersions=Constants.allManualVersions
            nextVersion=?Constants.nextVersion
            onChange=onVersionChange
            version
          />
          {if version === Constants.versions.next {
            <span className="text-fire-50 text-12">
              {React.string("This docs version is work in progress!")}
            </span>
          } else if version === Constants.versions.latest {
            <span className="text-gray-40 text-12">
              {React.string("This is the latest docs version")}
            </span>
          } else {
            React.null
          }}
        </div>
      </div>
      <div className="flex justify-center">
        <div className="w-full sm:grid sm:grid-cols-3 max-w-1280">
          languageManualColumn
          ecosystemColumn
          quickReferenceColumn
        </div>
      </div>
      <img
        className="hidden xl:block absolute bottom-0 right-0"
        style={ReactDOM.Style.make(~maxWidth="27.8rem", ())}
        src="/static/illu_index_rescript@2x.png"
      />
    </div>
  }
}

module MobileNav = {
  @react.component
  let make = (~route: string) => {
    let base = "font-normal mx-4 py-5 text-gray-20 border-b border-gray-80"
    let extLink = "block hover:cursor-pointer hover:text-white text-gray-60"
    <div className="border-gray-80 border-t">
      <ul>
        <li className=base>
          <Link href="/try" className={linkOrActiveLink(~target="/try", ~route)}>
            {React.string("Playground")}
          </Link>
        </li>
        <li className=base>
          <Link href="/blog" className={linkOrActiveLinkSubroute(~target="/blog", ~route)}>
            {React.string("Blog")}
          </Link>
        </li>
         <li className=base>
           <Link href="/community"  className={linkOrActiveLink(~target="/community", ~route)}>

               {React.string("Community")}

           </Link>
         </li>
        <li className=base>
          <a href=Constants.xHref rel="noopener noreferrer" className=extLink>
            {React.string("X")}
          </a>
        </li>
        <li className=base>
          <a href=Constants.blueSkyHref rel="noopener noreferrer" className=extLink>
            {React.string("Bluesky")}
          </a>
        </li>
        <li className=base>
          <a href=Constants.githubHref rel="noopener noreferrer" className=extLink>
            {React.string("GitHub")}
          </a>
        </li>
        <li className=base>
          <a href=Constants.discourseHref rel="noopener noreferrer" className=extLink>
            {React.string("Forum")}
          </a>
        </li>
      </ul>
    </div>
  }
}

/* isOverlayOpen: if the mobile overlay is toggled open */
@react.component
let make = (~fixed=true, ~isOverlayOpen: bool, ~setOverlayOpen: (bool => bool) => unit) => {
  let minWidth = "20rem"
  let router = Next.Router.useRouter()
  let route = router.route
  let url = router.route->Url.parse
  let version = url->Url.getVersionString

  let (collapsibles, setCollapsibles) = React.useState(_ => [
    {
      title: "Docs",
      href: `/docs/manual/${version}/api`,
      isActiveRoute: route => {
        let url = Url.parse(route)
        switch url {
        | {base: ["docs"]}
        | {base: ["docs", "react"]}
        | {base: ["docs", "gentype"]}
        | {base: ["docs", "manual"]} =>
          switch url.pagepath[0] {
          | Some("api") => false
          | _ => true
          }
        | _ => false
        }
      },
      state: Closed,
      children: <DocsSection />,
    },
  ])

  let isSubnavOpen = Array.find(collapsibles, c => c.state !== Closed) !== None

  let toggleOverlay = () => setOverlayOpen(prev => !prev)

  let resetCollapsibles = () => setCollapsibles(prev => Array.map(prev, c => {...c, state: Closed}))

  let navRef = React.useRef(Nullable.null)
  Hooks.useOutsideClick(ReactDOM.Ref.domRef(navRef), resetCollapsibles)

  /* let windowWidth = useWindowWidth() */

  /*
  // Don't allow hover behavior for collapsibles if mobile navigation is on
  let _allowHover = switch windowWidth {
  | Some(width) => width > 576 // Value noted in tailwind config
  | None => true
  }
 */

  // Client side navigation requires us to reset the collapsibles
  // whenever a route change had occurred, otherwise the collapsible
  // will stay open, even though you clicked a link
  React.useEffect(() => {
    open Next.Router.Events
    let {Next.Router.events: events} = router

    let onChangeComplete = _url => {
      resetCollapsibles()
      setOverlayOpen(_ => false)
    }

    events->on(#routeChangeComplete(onChangeComplete))
    events->on(#hashChangeComplete(onChangeComplete))

    Some(
      () => {
        events->off(#routeChangeComplete(onChangeComplete))
        events->off(#hashChangeComplete(onChangeComplete))
      },
    )
  }, [])

  let fixedNav = fixed ? "fixed top-0" : "relative"

  let onStateChange = (~id, state) => {
    setCollapsibles(prev => {
      Array.filterMap(prev, next => {
        if next.title === id {
          Some({...next, state})
        } else {
          None
        }
      })
    })
  }

  let collapsibleElements = Array.map(collapsibles, coll => {
    <CollapsibleLink
      key={coll.title}
      title={coll.title}
      state={coll.state}
      id={coll.title}
      allowHover={false}
      active={coll.isActiveRoute(route)}
      onStateChange>
      {coll.children}
    </CollapsibleLink>
  })

  <>
    <nav
      ref={ReactDOM.Ref.domRef(navRef)}
      id="header"
      style={ReactDOMStyle.make(~minWidth, ())}
      className={fixedNav ++ " items-center z-50 px-4 flex xs:justify-center w-full h-16 bg-gray-90 shadow text-white-80 text-14 transition duration-300 ease-out group-[.nav-disappear]:-translate-y-16 md:group-[.nav-disappear]:transform-none"}>
      <div className="flex justify-between items-center h-full w-full max-w-1280">
        <div className="h-8 w-8 lg:h-10 lg:w-32">
          <a
            href="/"
            className="block hover:cursor-pointer w-full h-full flex justify-center items-center font-bold">
            <img src="/static/nav-logo@2x.png" className="lg:hidden" />
            <img src="/static/nav-logo-full@2x.png" className="hidden lg:block" />
          </a>
        </div>
        /* Desktop horizontal navigation */
        <div
          className="flex items-center xs:justify-between w-full bg-gray-90 sm:h-auto sm:relative">
          <div
            className="flex ml-10 space-x-5 w-full max-w-320"
            style={ReactDOMStyle.make(~maxWidth="26rem", ())}>
            {collapsibleElements->React.array}
            <Link href={`/docs/manual/${version}/api`} className={linkOrActiveApiSubroute(~route)}>
              {React.string("API")}
            </Link>
            <Link
              href="/try"
              className={"hidden xs:block " ++ linkOrActiveLink(~target="/try", ~route)}>
              {React.string("Playground")}
            </Link>
            <Link
              href="/blog"
              className={"hidden xs:block " ++ linkOrActiveLinkSubroute(~target="/blog", ~route)}>
              {React.string("Blog")}
            </Link>
            <Link
              href="/community/overview"
              className={"hidden xs:block " ++ linkOrActiveLink(~target="/community", ~route)}>
              {React.string("Community")}
            </Link>
          </div>
          <div className="md:flex flex items-center">
            <Search />
            <div className="hidden md:flex items-center ml-5">
              <a href=Constants.githubHref rel="noopener noreferrer" className={"mr-5 " ++ link}>
                <Icon.GitHub className="w-6 h-6 opacity-50 hover:opacity-100" />
              </a>
              <a href=Constants.xHref rel="noopener noreferrer" className={"mr-5 " ++ link}>
                <Icon.X className="w-6 h-6 opacity-50 hover:opacity-100" />
              </a>
              <a href=Constants.blueSkyHref rel="noopener noreferrer" className={"mr-5 " ++ link}>
                <Icon.Bluesky className="w-6 h-6 opacity-50 hover:opacity-100" />
              </a>
              <a href=Constants.discourseHref rel="noopener noreferrer" className=link>
                <Icon.Discourse className="w-6 h-6 opacity-50 hover:opacity-100" />
              </a>
            </div>
          </div>
        </div>
      </div>
      /* Burger Button */
      <button
        className="h-full px-4 xs:hidden flex items-center hover:text-white"
        onClick={evt => {
          ReactEvent.Mouse.preventDefault(evt)
          resetCollapsibles()
          toggleOverlay()
        }}>
        <Icon.DrawerDots
          className={"h-1 w-auto block " ++ (isOverlayOpen ? "text-fire" : "text-gray-60")}
        />
      </button>
      /* Mobile overlay */
      <div
        style={ReactDOMStyle.make(~minWidth, ~top="4rem", ())}
        className={(
          isOverlayOpen && !isSubnavOpen ? "flex" : "hidden"
        ) ++ " sm:hidden flex-col fixed top-0 left-0 h-full w-full z-50 sm:w-9/12 bg-gray-100 sm:h-auto sm:flex sm:relative sm:flex-row sm:justify-between"}>
        <MobileNav route />
      </div>
    </nav>
    <div
      className={if isSubnavOpen {
        "fixed"
      } else {
        "hidden"
      } ++ " z-40 bg-gray-10-tr w-full h-full bottom-0"}
      style={
        open ReactDOM.Style
        make()
        ->unsafeAddProp("backdropFilter", "blur(2px)")
        ->unsafeAddProp("WebkitBackdropFilter", "blur(2px)")
      }
    />
  </>
}

let make = React.memo(make)
