open ReactRouter
open NavbarUtils

module MobileNav = {
  @react.component
  let make = (~route: Path.t) => {
    let base = "font-normal mx-4 py-5 text-gray-40 border-b border-gray-80"
    let extLink = "block hover:cursor-pointer hover:text-white text-gray-60"
    <ul
      className="border-gray-80 border-tn top-16 flex-col fixed h-full w-full z-50 sm:w-9/12 bg-gray-100 sm:h-auto sm:flex sm:relative sm:flex-row sm:justify-between"
    >
      <li className=base>
        <Link
          prefetch={#intent}
          to=#"/try"
          className={linkOrActiveLink(~target=#"/try", ~route)}
          onClick=toggleMobileOverlay
        >
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
  }
}

@react.component
let make = () => {
  let location = ReactRouter.useLocation()
  let route = location.pathname

  // TODO: close dialog when you click outside
  //   React.useEffect(() => {
  //     document->WebAPI.Document.addEventListener(Click, closeMobileOverlay)
  //     Some(() => document->WebAPI.Document.removeEventListener(Click, closeMobileOverlay))
  //     // None
  //   }, [])

  <dialog id="mobile-overlay">
    <MobileNav route />
  </dialog>
}
