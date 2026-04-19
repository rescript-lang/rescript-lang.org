open NavbarUtils
open ReactRouter

@react.component
let make = (~sidebar: option<React.element>=?, ~children) => {
  let {pathname} = useLocation()

  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-[176px] lg:translate-y-0"
  }

  let handleBackdropClick = (e: JsxEvent.Mouse.t) => {
    let target = e->JsxEvent.Mouse.target
    let currentTarget = e->JsxEvent.Mouse.currentTarget
    if target == currentTarget {
      closeMobileTertiaryDrawer()
    }
  }

  React.useEffect(() => {
    Some(closeMobileTertiaryDrawer)
  }, [])

  <>
    <nav
      dataTestId="navbar-tertiary"
      className={`shadow h-12 w-full bg-white dark:bg-gray-95 text-gray-60 dark:text-gray-30 border-b border-gray-20 dark:border-gray-80 sticky z-90 transition-transform duration-300 px-4
      ${navbarClasses}
      ${isDocRoute(~route=pathname) ? "top-28" : "top-16"}`}
    >
      <div className="flex items-center h-full w-full max-w-1280 m-auto">
        <button
          className="md:hidden mr-3 text-gray-60 dark:text-gray-30"
          onClick={toggleMobileTertiaryDrawer}
          ariaLabel="Toggle navigation menu"
          type_="button"
        >
          <img className="h-4 dark:invert" src="/ic_sidebar_drawer.svg" />
        </button>
        <div
          className="truncate overflow-x-auto touch-scroll flex items-center space-x-4 justify-between mr-4 w-full"
        >
          {children}
        </div>
      </div>
    </nav>
    <dialog
      id="mobile-tertiary-drawer"
      onClick={handleBackdropClick}
      className={`${isDocRoute(~route=pathname)
          ? "top-40"
          : "top-28"} flex-col h-full w-full z-50 bg-white dark:bg-gray-95 text-gray-60 dark:text-gray-30 overflow-y-auto pb-8 backdrop:bg-transparent`}
    >
      {switch sidebar {
      | Some(sidebar) => sidebar
      | None => React.null
      }}
    </dialog>
  </>
}
