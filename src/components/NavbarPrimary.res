open ReactRouter

module LeftContent = {
  @react.component
  let make = () => {
    <div
      className="row-start-1 justify-self-start col-[content] flex items-center h-full  space-x-5 text-gray-40"
    >
      <Link to=#"/" className="h-8 w-8 lg:h-10 lg:w-32 flex items-center">
        <img
          className="lg:hidden" alt="ReScript Home" src="/brand/rescript-brandmark.svg" width="128"
        />
        <img
          className="hidden lg:block" alt="ReScript Home" src="/brand/rescript-logo.svg" width="116"
        />
      </Link>
      <Link
        to=#"/docs/manual/introduction" className="font-medium text-fire-30 border-b border-fire"
      >
        {React.string("Docs")}
      </Link>
      <Link to=#"/try" className="hover:text-fire-30"> {React.string("Playground")} </Link>
      <Link to=#"/blog" className="hover:text-fire-30"> {React.string("Blog")} </Link>
      <Link to=#"/community/overview" className="hover:text-fire-30">
        {React.string("Community")}
      </Link>
    </div>
  }
}

module RightContent = {
  @react.component
  let make = () => {
    <div
      className="row-start-1 justify-self-end col-[content] grid grid-flow-col items-center space-x-5 text-gray-40"
    >
      <Search />
      <a href=Constants.githubHref rel="noopener noreferrer" ariaLabel="GitHub">
        <Icon.GitHub className="w-6 h-6 opacity-50 hover:opacity-100 " />
      </a>
      <a href=Constants.xHref rel="noopener noreferrer" ariaLabel="X (formerly Twitter)">
        <Icon.X className="w-6 h-6 opacity-50 hover:opacity-100" />
      </a>
      <a href=Constants.blueSkyHref rel="noopener noreferrer" ariaLabel="Bluesky">
        <Icon.Bluesky className="w-6 h-6 opacity-50 hover:opacity-100" />
      </a>
      <a href=Constants.discourseHref rel="noopener noreferrer" ariaLabel="Forum">
        <Icon.Discourse className="w-6 h-6 opacity-50 hover:opacity-100" />
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

  <nav
    id="main-navbar"
    className={`
    sticky top-0 h-16 w-full items-center bg-gray-90 shadow text-white-80 text-14 z-100
    grid grid-rows-1 grid-cols-[[full-start]_minmax(1rem,1fr)_[content-start]_min(1280px,100%-2rem)_[content-end]_minmax(1rem,1fr)_[full-end]]
    transition-transform duration-300 ${navbarClasses}
    `}
  >
    <LeftContent />
    <RightContent />
  </nav>
}
