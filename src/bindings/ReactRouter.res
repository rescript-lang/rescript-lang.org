type navigateOptions = {replace?: bool}

@module("react-router-dom")
external navigate: (string, ~options: navigateOptions=?) => unit = "navigate"

// https://api.reactrouter.com/v7/functions/react_router.useNavigate.html
@module("react-router")
external useNavigate: unit => string => unit = "useNavigate"

@module("react-router")
external useSearchParams: unit => (WebAPI.URLAPI.urlSearchParams, {..} => unit) = "useSearchParams"

@module("react-router")
external useLoaderData: unit => 'a = "useLoaderData"

/* The types for this are auto-generated from the react-router.config.mjs file */
type path = {pathname: Path.t, search?: string, hash?: option<string>}

module Loader = {
  type loaderArgs = {request: WebAPI.FetchAPI.request}
  type t<'a> = loaderArgs => promise<'a>
}

module Outlet = {
  @module("react-router") @react.component
  external make: unit => React.element = "Outlet"
}

module ScrollRestoration = {
  @module("react-router") @react.component
  external make: unit => React.element = "ScrollRestoration"
}

module Meta = {
  @module("react-router") @react.component
  external make: unit => React.element = "Meta"
}

module Links = {
  @module("react-router") @react.component
  external make: unit => React.element = "Links"
}

module Scripts = {
  @module("react-router") @react.component
  external make: unit => React.element = "Scripts"
}

module Link = {
  type prefetch = [#none | #intent | #render | #viewport]

  @module("react-router") @react.component
  external make: (
    ~children: React.element=?,
    ~className: string=?,
    ~target: string=?,
    ~to: Path.t,
    ~preventScrollReset: bool=?,
    ~prefetch: prefetch=?,
  ) => React.element = "Link"

  module Path = {
    type to = {hash?: string, pathname?: Path.t, search?: string}

    @module("react-router") @react.component
    external make: (
      ~onClick: ReactEvent.Mouse.t => unit=?,
      ~children: React.element=?,
      ~className: string=?,
      ~target: string=?,
      ~id: string=?,
      ~to: to,
      ~preventScrollReset: bool=?,
      ~prefetch: prefetch=?,
    ) => React.element = "Link"
  }

  module String = {
    @module("react-router") @react.component
    external make: (
      ~title: string=?,
      ~onClick: ReactEvent.Mouse.t => unit=?,
      ~children: React.element=?,
      ~className: string=?,
      ~target: string=?,
      ~to: string,
      ~preventScrollReset: bool=?,
      ~relative: string=?,
      ~prefetch: prefetch=?,
    ) => React.element = "Link"
  }
}

@module("react-router")
external useLocation: unit => path = "useLocation"

module Routes = {
  type t = {
    id: string,
    path?: string,
  }

  type config = array<t>

  @module("@react-router/dev/routes")
  external index: string => t = "index"

  type routeOptions = {id?: string}

  @module("@react-router/dev/routes")
  external route: (string, string, ~options: routeOptions=?) => t = "route"

  @module("@react-router/dev/routes")
  external layout: (string, array<t>) => t = "layout"

  @module("react-router-mdx/server")
  external mdxRoutes: string => array<t> = "routes"
}
