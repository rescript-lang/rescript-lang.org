open ReactRouter
open NavbarUtils

module MobileDrawerButton = {
  @react.component
  let make = (~hidden: bool) =>
    <button className={(hidden ? "hidden " : "") ++ "md:hidden mr-3"} popoverTarget="sidebar">
      <img className="h-4" src="/ic_sidebar_drawer.svg" />
    </button>
}

@react.component
let make = () => {
  let location = ReactRouter.useLocation()
  let route = location.pathname

  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-[128px] lg:translate-y-0"
  }

  <nav
    dataTestId="navbar-secondary"
    className={"text-12 md:text-14 shadow h-12 w-full bg-white sticky z-95 top-16 transition-transform duration-300 px-4 " ++
    navbarClasses}
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
        prefetch=#intent to=#"/docs/manual/api" className={isActiveLink(~includes="/api", ~route)}
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
}
