module Link = Next.Link

let link = "no-underline block hover:cursor-pointer hover:text-fire-30 mb-px"
let activeLink = "font-medium text-fire-30 border-b border-fire"

let linkOrActiveLink = (~target, ~route) => target === route ? activeLink : link

let linkOrActiveLinkSubroute = (~target, ~route) =>
  String.startsWith(route, target) ? activeLink : link

let isActiveLink = (~includes: string, ~excludes: option<string>=?, ~route: string) => {
  // includes means we want the lnk to be active if it contains the expected text
  let includes = route->String.includes(includes)
  // excludes allows us to not have links be active even if they do have the includes text
  let excludes = switch excludes {
  | Some(excludes) => route->String.includes(excludes)
  | None => false
  }
  includes && !excludes ? activeLink : link
}

let isDocRoute = (~route) =>
  route->String.includes("/docs/") || route->String.includes("/syntax-lookup")

let isDocRouteActive = (~route) => isDocRoute(~route) ? activeLink : link

module MobileNav = {
  @react.component
  let make = (~route: string) => {
    let base = "font-normal mx-4 py-5 text-gray-40 border-b border-gray-80"
    let extLink = "block hover:cursor-pointer hover:text-white text-gray-60"
    <div className="border-gray-80 border-tn">
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
          <Link href="/community" className={linkOrActiveLink(~target="/community", ~route)}>
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

  let toggleOverlay = () => setOverlayOpen(prev => !prev)

  let fixedNav = fixed ? "fixed top-0" : "relative"

  <>
    <header
      id="header"
      style={ReactDOMStyle.make(~minWidth, ())}
      className={fixedNav ++ " items-center z-50 w-full transition duration-300 ease-out group-[.nav-disappear]:-translate-y-16 md:group-[.nav-disappear]:transform-none"}>
      <nav className="px-4 flex xs:justify-center bg-gray-90 shadow h-16 text-white-80 text-14">
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
              className="flex ml-10 space-x-5 w-full max-w-320 text-gray-40"
              style={ReactDOMStyle.make(~maxWidth="26rem", ())}>
              <Link
                href={`/docs/manual/${version}/introduction`} className={isDocRouteActive(~route)}>
                {React.string("Docs")}
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
          className="h-full px-4 xs:hidden flex items-center hover:text-white"
          onClick={evt => {
            ReactEvent.Mouse.preventDefault(evt)
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
            isOverlayOpen ? "flex" : "hidden"
          ) ++ " sm:hidden flex-col fixed top-0 left-0 h-full w-full z-50 sm:w-9/12 bg-gray-100 sm:h-auto sm:flex sm:relative sm:flex-row sm:justify-between"}>
          <MobileNav route />
        </div>
      </nav>
      // This is a subnav for documentation pages
      {isDocRoute(~route)
        ? <nav
            id="docs-subnav"
            className="bg-white z-50 px-4 w-full h-12 shadow text-gray-60 text-12 md:text-14 transition duration-300 ease-out group-[.nav-disappear]:-translate-y-16 md:group-[.nav-disappear]:transform-none">
            <div
              className="pl-30 flex gap-2 md:gap-6 lg:gap-10 items-center h-full w-full max-w-md">
              <Link
                href={`/docs/manual/${version}/introduction`}
                className={isActiveLink(~includes="/docs/manual/", ~excludes="/api", ~route)}>
                {React.string("Language Manual")}
              </Link>
              <Link
                href={`/docs/manual/${version}/api`}
                className={isActiveLink(~includes="/api", ~route)}>
                {React.string("API")}
              </Link>
              <Link
                href={`/syntax-lookup`}
                className={isActiveLink(~includes="/syntax-lookup", ~route)}>
                {React.string("Syntax Lookup")}
              </Link>
              <Link
                href={`/docs/react/latest/introduction`}
                className={isActiveLink(~includes="/docs/react/", ~route)}>
                {React.string("React")}
              </Link>
            </div>
          </nav>
        : React.null}
    </header>
  </>
}

let make = React.memo(make)
