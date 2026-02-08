@react.component
let make = () => {
  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-full lg:translate-y-0"
  }

  <nav
    dataTestId="navbar-primary"
    className={"h-16 w-full bg-gray-90 sticky z-100 top-0 transition-transform duration-300 " ++
    navbarClasses}
  >
  </nav>
}
