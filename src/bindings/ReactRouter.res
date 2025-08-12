@module("react-router-dom")
external navigate: string => unit = "navigate"
// TODO: get this to use the actual paths available
// I can create a script that will generate the paths from the route file and create a rescript file for the types
// for example, <Link to=#index />
type path = {pathname: string, search?: string, hash?: string}

module Outlet = {
  @module("react-router") @react.component
  external make: unit => React.element = "Outlet"
}

module Link = {
  @unboxed
  type to =
    | Url(string)
    | Path

  @module("react-router") @react.component
  external make: (
    ~children: React.element,
    ~className: string=?,
    ~target: string=?,
    ~to: to,
  ) => React.element = "Link"
}

@module("react-router")
external useLocation: unit => path = "useLocation"
