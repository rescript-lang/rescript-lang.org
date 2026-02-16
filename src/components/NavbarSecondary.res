let link = "no-underline block hover:cursor-pointer hover:text-fire-30 mb-px"
let activeLink = "font-medium text-fire-30 border-b border-fire"

let linkOrActiveLink = (~target: Path.t, ~route: Path.t) => target === route ? activeLink : link

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

module MobileDrawerButton = {
  @react.component
  let make = (~hidden: bool) =>
    <button className={(hidden ? "hidden " : "") ++ "md:hidden mr-3"} popoverTarget="sidebar">
      <img className="h-4" src="/ic_sidebar_drawer.svg" />
    </button>
}

@react.component
let make = (~children) => {
  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-[128px] lg:translate-y-0"
  }

  <nav
    dataTestId="navbar-secondary"
    className={"text-12 md:text-14 shadow h-12 w-full bg-white sticky z-95 top-16 transition-transform duration-300 " ++
    navbarClasses}
  >
    <div className="px-4 flex gap-6 lg:gap-10 items-center h-full w-full max-w-1280 m-auto">
      <MobileDrawerButton hidden=false />
      {children}
    </div>
  </nav>
}
