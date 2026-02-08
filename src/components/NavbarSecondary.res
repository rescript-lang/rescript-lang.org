@react.component
let make = () => {
  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-[128px] lg:translate-y-0"
  }

  <nav
    dataTestId="navbar-secondary"
    className={"h-16 w-full bg-gray-40 sticky z-95 top-16 transition-transform duration-300 " ++
    navbarClasses}
  >
  </nav>
}
