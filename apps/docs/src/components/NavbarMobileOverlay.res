open ReactRouter
open NavbarUtils

module MobileNav = {
  @react.component
  let make = (~route: Path.t) => {
    let base = "font-normal mx-4 py-5 text-gray-40 border-b border-gray-80"
    let extLink = "block hover:cursor-pointer hover:text-white text-gray-60"
    <ul dataTestId="mobile-nav">
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
          onClick=toggleMobileOverlay
        >
          {React.string("Blog")}
        </Link>
      </li>
      <li className=base>
        <Link
          prefetch={#intent}
          to=#"/community/overview"
          className={linkOrActiveLink(~target=#"/community/overview", ~route)}
          onClick=toggleMobileOverlay
        >
          {React.string("Community")}
        </Link>
      </li>
      <li className=base>
        <Link
          prefetch={#intent}
          to=#"/packages"
          className={linkOrActiveLink(~target=#"/packages", ~route)}
          onClick=toggleMobileOverlay
        >
          {React.string("Packages")}
        </Link>
      </li>
      <li className=base>
        <a
          href=Constants.xHref
          rel="noopener noreferrer"
          className=extLink
          ariaLabel="X (formerly Twitter)"
          onClick=closeMobileOverlay
        >
          {React.string("X")}
        </a>
      </li>
      <li className=base>
        <a
          href=Constants.blueSkyHref
          rel="noopener noreferrer"
          className=extLink
          onClick=closeMobileOverlay
        >
          {React.string("Bluesky")}
        </a>
      </li>
      <li className=base>
        <a
          href=Constants.githubHref
          rel="noopener noreferrer"
          className=extLink
          onClick=closeMobileOverlay
        >
          {React.string("GitHub")}
        </a>
      </li>
      <li className=base>
        <a
          href=Constants.discourseHref
          rel="noopener noreferrer"
          className=extLink
          onClick=closeMobileOverlay
        >
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

  let handleBackdropClick = (e: JsxEvent.Mouse.t) => {
    let target = e->JsxEvent.Mouse.target
    let currentTarget = e->JsxEvent.Mouse.currentTarget
    if target == currentTarget {
      closeMobileOverlay()
    }
  }

  React.useEffect(() => {
    // Make sure the dialog element closes if the component unmounts
    Some(closeMobileOverlay)
  }, [])

  <dialog
    id="mobile-overlay"
    onClick={handleBackdropClick}
    className="top-16 flex-col h-full w-full z-50 bg-gray-100  overflow-scroll pb-8"
  >
    <MobileNav route />
  </dialog>
}
