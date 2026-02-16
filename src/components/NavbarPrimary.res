open ReactRouter
open NavbarUtils

let isActive = (~url, ~pathname: Path.t) => {
  (pathname :> string)->String.includes(url)
    ? "hover:text-fire-30 font-medium text-fire-30 border-b border-fire"
    : "hover:text-fire-30"
}

module LeftContent = {
  @react.component
  let make = () => {
    let {pathname} = useLocation()
    <div
      dataTestId="navbar-primary-left-content"
      className="row-start-1 justify-self-start col-[content] flex items-center h-full  space-x-5 text-gray-40"
    >
      <Link to=#"/" className="h-8 w-8 lg:h-10 lg:w-32 flex items-center" ariaLabel="homepage">
        <img
          className="lg:hidden" alt="ReScript Home" src="/brand/rescript-brandmark.svg" width="128"
        />
        <img
          className="hidden lg:block" alt="ReScript Home" src="/brand/rescript-logo.svg" width="116"
        />
      </Link>
      <Link to=#"/docs/manual/introduction" className={isActive(~url="/docs", ~pathname)}>
        {React.string("Docs")}
      </Link>
      <Link to=#"/try" className={isActive(~url="/try", ~pathname) ++ " hidden md:block"}>
        {React.string("Playground")}
      </Link>
      <Link to=#"/blog" className={isActive(~url="/blog", ~pathname) ++ " hidden md:block"}>
        {React.string("Blog")}
      </Link>
      <Link
        to=#"/community/overview"
        className={isActive(~url="/community", ~pathname) ++ " hidden md:block"}
      >
        {React.string("Community")}
      </Link>
    </div>
  }
}

module RightContent = {
  @react.component
  let make = () => {
    let iconClasses = "w-6 h-6 opacity-50 hover:opacity-100"
    let linkClasses = "hidden md:block"
    <div
      dataTestId="navbar-primary-right-content"
      className="row-start-1 justify-self-end col-[content] grid grid-flow-col items-center space-x-5 text-gray-40"
    >
      <Search />
      <button
        className={"h-1 w-auto block md:hidden opacity-50 hover:opacity-100 m-0"}
        onClick={toggleMobileOverlay}
        ariaLabel="Toggle additional menu"
        dataTestId="toggle-mobile-overlay"
      >
        <Icon.DrawerDots />
      </button>
      <a
        href=Constants.githubHref rel="noopener noreferrer" ariaLabel="GitHub" className=linkClasses
      >
        <Icon.GitHub className=iconClasses />
      </a>
      <a
        href=Constants.xHref
        rel="noopener noreferrer"
        ariaLabel="X (formerly Twitter)"
        className=linkClasses
      >
        <Icon.X className=iconClasses />
      </a>
      <a
        href=Constants.blueSkyHref
        rel="noopener noreferrer"
        ariaLabel="Bluesky"
        className=linkClasses
      >
        <Icon.Bluesky className=iconClasses />
      </a>
      <a
        href=Constants.discourseHref
        rel="noopener noreferrer"
        ariaLabel="Forum"
        className=linkClasses
      >
        <Icon.Discourse className=iconClasses />
      </a>
    </div>
  }
}

@react.component
let make = () => {
  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-full md:translate-y-0"
  }

  <>
    <nav
      dataTestId="navbar-primary"
      className={`
    sticky top-0 h-16 w-full items-center bg-gray-90 shadow text-white-80 text-14 z-100
    grid grid-rows-1 grid-cols-[[full-start]_minmax(1rem,1fr)_[content-start]_min(1280px,100%-2rem)_[content-end]_minmax(1rem,1fr)_[full-end]]
    transition-transform duration-300 ${navbarClasses}
    `}
    >
      <LeftContent />
      <RightContent />
    </nav>
    <NavbarMobileOverlay />
  </>
}
