module Link = ReactRouter.Link

let link = "no-underline block hover:cursor-pointer hover:text-fire-30 mb-px"
let activeLink = "font-medium text-fire-30 border-b border-fire"

let linkOrActiveLink = (~target: Path.t, ~route: Path.t) => target === route ? activeLink : link

let linkOrActiveLinkSubroute = (~target: Path.t, ~route: Path.t) =>
  String.startsWith((route :> string), (target :> string)) ? activeLink : link

let isActiveLink = (~includes: string, ~excludes: option<string>=?, ~route: Path.t) => {
  let route = (route :> string)
  // includes means we want the lnk to be active if it contains the expected text
  let includes = route->String.includes(includes)
  // excludes allows us to not have links be active even if they do have the includes text
  let excludes = switch excludes {
  | Some(excludes) => route->String.includes(excludes)
  | None => false
  }
  includes && !excludes ? activeLink : link
}

let isDocRoute = (~route: Path.t) => {
  let route = (route :> string)
  route->String.includes("/docs/") || route->String.includes("/syntax-lookup") || route == "/docs"
}

let isDocRouteActive = (~route: Path.t) => isDocRoute(~route) ? activeLink : link

module MobileNav = {
  @react.component
  let make = (~route: Path.t) => {
    let base = "font-normal mx-4 py-5 text-gray-40 border-b border-gray-80"
    let extLink = "block hover:cursor-pointer hover:text-white text-gray-60"
    <div className="border-gray-80 border-tn">
      <ul>
        <li className=base>
          <Link prefetch={#intent} to=#"/try" className={linkOrActiveLink(~target=#"/try", ~route)}>
            {React.string("Playground")}
          </Link>
        </li>
        <li className=base>
          <Link
            prefetch={#intent}
            to=#"/blog"
            className={linkOrActiveLinkSubroute(~target=#"/blog", ~route)}
          >
            {React.string("Blog")}
          </Link>
        </li>
        <li className=base>
          <Link
            prefetch={#intent}
            to=#"/community/overview"
            className={linkOrActiveLink(~target=#"/community/overview", ~route)}
          >
            {React.string("Community")}
          </Link>
        </li>
        <li className=base>
          <Link
            prefetch={#intent}
            to=#"/packages"
            className={linkOrActiveLink(~target=#"/packages", ~route)}
          >
            {React.string("Packages")}
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

/* isOverlayOpen: if the mobile sidebar is toggled open */
@react.component
let make = (~fixed=true, ~isOverlayOpen: bool, ~setOverlayOpen: (bool => bool) => unit) => {
  let location = ReactRouter.useLocation()
  let route = location.pathname

  // TODO: post RR7 - I am not sure we need this, but it was fidgety to get this working right so I am leaving it for now
  let (_isLocked, toggleScrollLock) = ScrollLockContext.useScrollLock()

  let toggleOverlay = () => {
    setOverlayOpen(prev => !prev)
    toggleScrollLock(prev => !prev)
  }

  let fixedNavClassName = fixed ? "fixed top-0" : "relative"

  <>
    <header
      id="header"
      className={fixedNavClassName ++ " items-center z-50 w-full transition duration-300 ease-out group-[.nav-disappear]:-translate-y-16 md:group-[.nav-disappear]:-translate-y-0 min-w-[20rem]"}
    >
      <nav
        className="px-4 flex xs:justify-center bg-gray-90 shadow h-16 text-white-80 text-14"
        id="main-navbar"
      >
        <div className="flex justify-between items-center h-full w-full max-w-1280">
          <div className="h-8 w-8 lg:h-10 lg:w-32">
            <Link.String
              prefetch={#intent}
              to="/"
              className="block hover:cursor-pointer w-full h-full flex justify-center items-center font-bold"
            >
              <img src="/nav-logo@2x.png" className="lg:hidden" />
              <img src="/nav-logo-full@2x.png" className="hidden lg:block" />
            </Link.String>
          </div>

          /* Desktop horizontal navigation */
          <div
            className="flex items-center xs:justify-between w-full bg-gray-90 sm:h-auto sm:relative"
          >
            <div className="flex ml-10 space-x-5 w-full text-gray-40 max-w-104">
              <Link
                to=#"/docs/manual/introduction"
                className={isDocRouteActive(~route)}
                prefetch=#intent
              >
                {React.string("Docs")}
              </Link>

              <Link
                to=#"/try"
                prefetch=#intent
                className={"hidden xs:block " ++ linkOrActiveLink(~target=#"/try", ~route)}
              >
                {React.string("Playground")}
              </Link>

              <Link
                to=#"/blog"
                prefetch=#intent
                className={"hidden xs:block " ++ linkOrActiveLinkSubroute(~target=#"/blog", ~route)}
              >
                {React.string("Blog")}
              </Link>

              <Link
                prefetch=#intent
                to=#"/community/overview"
                className={"hidden xs:block " ++
                linkOrActiveLink(~target=#"/community/overview", ~route)}
              >
                {React.string("Community")}
              </Link>

              <Link
                prefetch=#intent
                to=#"/packages"
                className={"hidden xs:block " ++ linkOrActiveLink(~target=#"/packages", ~route)}
              >
                {React.string("Packages")}
              </Link>
            </div>
            <div className="md:flex flex items-center text-gray-60">
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
          id="burger-button"
          className="h-full px-4 xs:hidden flex items-center hover:text-white"
          onClick={evt => {
            ReactEvent.Mouse.preventDefault(evt)
            toggleOverlay()
          }}
        >
          <Icon.DrawerDots
            className={"h-1 w-auto block " ++ (isOverlayOpen ? "text-fire" : "text-gray-60")}
          />
        </button>

        /* Mobile overlay */
        <div
          id="mobile-overlay"
          className={(
            isOverlayOpen ? "flex" : "hidden"
          ) ++ " top-16 sm:hidden flex-col fixed top-0 left-0 h-full w-full z-50 sm:w-9/12 bg-gray-100 sm:h-auto sm:flex sm:relative sm:flex-row sm:justify-between"}
        >
          <MobileNav route />
        </div>
      </nav>
      // This is a subnav for documentation pages
      {isDocRoute(~route)
        ? <nav
            id="doc-navbar"
            className="bg-white z-50 px-4 w-full h-12 shadow text-gray-60 text-12 md:text-14 transition duration-300 ease-out group-[.nav-disappear]:-translate-y-32 md:group-[.nav-disappear]:translate-y-0"
          >
            <div className="flex gap-6 lg:gap-10 items-center h-full w-full max-w-1280 m-auto">
              <Link
                prefetch=#intent
                to=#"/docs/manual/introduction"
                className={isActiveLink(~includes="/docs/manual/", ~excludes="/api", ~route)}
              >
                {React.string("Language Manual")}
              </Link>
              <Link
                prefetch=#intent
                to=#"/docs/manual/api"
                className={isActiveLink(~includes="/api", ~route)}
              >
                {React.string("API")}
              </Link>
              <Link
                prefetch=#intent
                to=#"/syntax-lookup"
                className={isActiveLink(~includes="/syntax-lookup", ~route)}
              >
                {React.string("Syntax Lookup")}
              </Link>
              <Link
                prefetch=#intent
                to=#"/docs/react/introduction"
                className={isActiveLink(~includes="/docs/react/", ~route)}
              >
                {React.string("React")}
              </Link>
            </div>
          </nav>
        : React.null}
    </header>
  </>
}

let make = React.memo(make)
