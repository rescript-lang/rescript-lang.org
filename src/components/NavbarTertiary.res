@react.component
let make = () => {
  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-[192px] lg:translate-y-0"
  }

  <nav
    dataTestId="navbar-secondary"
    className={"h-16 w-full bg-gray-20 sticky z-90 top-32 transition-transform duration-300 " ++
    navbarClasses}
  >
  </nav>
}
