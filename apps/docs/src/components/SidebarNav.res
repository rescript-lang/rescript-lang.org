module Link = ReactRouter.Link

module Toc = {
  @react.component
  let make = (~entries: array<TableOfContents.entry>, ~onClick) =>
    <ul className="mt-3 py-1 mb-4 border-l border-fire-10">
      {Array.map(entries, ({header, href}) => {
        <li key=header className="pl-2 mt-2 first:mt-1" dataTestId=header>
          <Link.String
            prefetch={#intent}
            onClick={evt => {
              evt->ReactEvent.Mouse.preventDefault
              WebAPI.Document.getElementById(
                document,
                href->String.replace("#", ""),
              )->WebAPI.Element.scrollIntoView_alignToTop
              onClick()
            }}
            to={"#" ++ href->Url.normalizeAnchor}
            className="font-normal block text-14 text-gray-40 leading-tight hover:text-gray-80"
            preventScrollReset=true
          >
            {React.string(
              header
              ->String.replaceRegExp(/<[^>]+>/g, "")
              ->String.replaceRegExp(/([\r\n]+ +)+/g, ""),
            )}
          </Link.String>
        </li>
      })->React.array}
    </ul>
}

module Title = {
  @react.component
  let make = (~children) => {
    let className = "hl-overline text-gray-80 mt-5" //overline

    <div className> children </div>
  }
}

module NavItem = {
  // Navigation point information
  type t = {
    name: string,
    href: string,
  }

  @react.component
  let make = (
    ~getActiveToc: option<t => option<TableOfContents.t>>=?,
    ~isHidden=false,
    ~isItemActive: t => bool=_nav => false,
    ~items: array<t>,
    ~onClick,
  ) =>
    <ul className="mt-2 text-14 font-medium">
      {Array.map(items, m => {
        let hidden = isHidden ? "hidden" : "block"
        let active = isItemActive(m)
          ? ` bg-fire-5 text-red-500 leading-5 -ml-2 pl-2 font-medium block hover:bg-fire-70 `
          : ""

        let activeToc = switch getActiveToc {
        | Some(getActiveToc) => getActiveToc(m)
        | None => None
        }

        <li key=m.name className={hidden ++ " mt-1 leading-4"}>
          <Link.String
            to=m.href
            prefetch={#intent}
            className={"block py-1 md:h-auto tracking-tight text-gray-60 rounded-sm hover:bg-gray-20 hover:-ml-2 hover:py-1 hover:pl-2 " ++
            active}
          >
            {React.string(m.name)}
          </Link.String>
          {switch activeToc {
          | Some({entries}) =>
            if Array.length(entries) === 0 {
              React.null
            } else {
              <Toc entries onClick />
            }
          | None => React.null
          }}
        </li>
      })->React.array}
    </ul>
}

module Category = {
  type t = {
    name: string,
    items: array<NavItem.t>,
  }

  @react.component
  let make = (
    ~category: t,
    ~getActiveToc=?,
    ~isItemActive: option<NavItem.t => bool>=?,
    ~onClick,
  ) =>
    <div key=category.name className="my-10">
      <Title> {React.string(category.name)} </Title>
      <NavItem ?isItemActive ?getActiveToc items=category.items onClick />
    </div>
}

// subitems: list of functions inside given module (defined by route)
@react.component
let make = (
  ~categories: array<Category.t>,
  ~route: Path.t,
  ~toplevelNav=React.null,
  ~title as _: option<string>=?,
  ~preludeSection=React.null,
  ~activeToc: option<TableOfContents.t>=?,
  ~isOpen: bool,
  ~toggle: unit => unit,
) => {
  let currentRoute = (route :> string)->Url.normalizePath
  let isItemActive = (navItem: NavItem.t) => navItem.href->Url.normalizePath === currentRoute

  let getActiveToc = (navItem: NavItem.t) => {
    if navItem.href->Url.normalizePath === currentRoute {
      activeToc
    } else {
      None
    }
  }

  <>
    <div
      id="sidebar"
      className={(
        isOpen ? "fixed w-full left-0 h-full z-20 min-w-320" : "hidden "
      ) ++ " md:block md:w-48 md:-ml-4 lg:w-1/5 h-auto md:relative overflow-y-visible bg-white md:mt-0 min-w-48"}
    >
      <aside
        id="sidebar-content"
        dataTestId="sidebar-content"
        className="h-full relative top-0 px-4 w-full block md:top-40 md:sticky border-r border-gray-20 overflow-y-auto pb-24 max-h-[calc(100vh-10rem)] pt-8"
      >
        <button
          onClick={evt => {
            ReactEvent.Mouse.preventDefault(evt)
            toggle()
          }}
          className="md:hidden h-16 flex pt-2 right-4 absolute"
        >
          <Icon.Close />
        </button>
        <div className="flex justify-between" dataTestId="sidebar-toplevel-nav">
          <div className="w-3/4 md:w-full"> toplevelNav </div>
        </div>

        preludeSection

        /* Firefox ignores padding in scroll containers, so we need margin
             to make a bottom gap for the sidebar.
             See https://stackoverflow.com/questions/29986977/firefox-ignores-padding-when-using-overflowscroll
 */
        <div className="mb-56">
          {categories
          ->Array.map(category => {
            <div key=category.name>
              <Category getActiveToc isItemActive category onClick=toggle />
            </div>
          })
          ->React.array}
        </div>
      </aside>
    </div>
  </>
}
