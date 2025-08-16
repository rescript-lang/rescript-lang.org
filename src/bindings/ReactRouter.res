open WebAPI

@module("react-router-dom")
external navigate: string => unit = "navigate"
// TODO: get this to use the actual paths available
// I can create a script that will generate the paths from the route file and create a rescript file for the types
// for example, <Link to=#index />
type path = {pathname: string, search?: string, hash?: string}

module Loader = {
  type loaderArgs = {request: WebAPI.FetchAPI.request}
  type t<'a> = loaderArgs => promise<'a>
}

module Outlet = {
  @module("react-router") @react.component
  external make: unit => React.element = "Outlet"
}

module Scripts = {
  @module("react-router") @react.component
  external make: unit => React.element = "Scripts"
}

module Link = {
  @unboxed
  type to =
    | Url(string)
    | Path

  @module("react-router") @react.component
  external make: (
    ~children: React.element=?,
    ~className: string=?,
    ~target: string=?,
    ~to: to,
  ) => React.element = "Link"
}

@module("react-router")
external useLocation: unit => path = "useLocation"

module Routes = {
  type t

  type config = array<t>

  @module("@react-router/dev/routes")
  external index: string => t = "index"

  @module("@react-router/dev/routes")
  external route: (string, string) => t = "route"
}

module Mdx = {
  type t

  type attributes = {
    title: string,
    description?: string,
  }

  @module("react-router-mdx/server")
  external routes: string => array<Routes.t> = "routes"

  @module("react-router-mdx/server")
  external loadMdx: FetchAPI.request => promise<t> = "loadMdx"

  @module("react-router-mdx/client")
  external useMdxAttributes: unit => attributes = "useMdxAttributes"

  @module("react-router-mdx/client")
  external useMdxComponent: unit => Jsx.component<'a> = "useMdxComponent"
}
