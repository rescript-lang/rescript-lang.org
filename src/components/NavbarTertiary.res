@react.component
let make = () => {
  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  //
  | Down(_) => "-translate-y-[176px] lg:translate-y-0"
  }

  <nav
    dataTestId="navbar-secondary"
    className={"shadow h-16 w-full bg-gray-20 sticky z-90 top-28 transition-transform duration-300 " ++
    navbarClasses}
  >
  </nav>
}
