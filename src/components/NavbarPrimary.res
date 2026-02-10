open ReactRouter

@react.component
let make = () => {
  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-full lg:translate-y-0"
  }

  <nav
    dataTestId="navbar-primary"
    className={"shadow h-16 w-full bg-gray-90 sticky z-100 top-0 transition-transform duration-300 items-center ease-out group-[.nav-disappear]:-translate-y-16 min-w-[20rem]" ++
    navbarClasses}
  >
    <Link.String
      prefetch={#intent}
      to="/"
      className="h-8 w-8 lg:h-10 lg:w-32 block hover:cursor-pointer w-full justify-center items-center font-bold"
    >
      <img src="/brand/rescript-brandmark.svg" className="lg:hidden" alt="ReScript Home" />
      <img src="/brand/rescript-logo.svg" className="hidden lg:block" alt="ReScript Home" />
    </Link.String>
  </nav>
}
