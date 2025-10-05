open WebAPI

@module("react-router-dom")
external navigate: string => unit = "navigate"

// https://api.reactrouter.com/v7/functions/react_router.useNavigate.html
@module("react-router")
external useNavigate: unit => string => unit = "useNavigate"

@module("react-router")
external useSearchParams: unit => ({..}, {..} => unit) = "useSearchParams"

@module("react-router")
external useLoaderData: unit => 'a = "useLoaderData"

/* The types for this are auto-generated from the react-router.config.mjs file */
type path = {pathname: Path.t, search?: string, hash?: string}

module Loader = {
  type loaderArgs = {request: WebAPI.FetchAPI.request}
  type t<'a> = loaderArgs => promise<'a>
}

module Outlet = {
  @module("react-router") @react.component
  external make: unit => React.element = "Outlet"
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
  @module("react-router") @react.component
  external make: (
    ~children: React.element=?,
    ~className: string=?,
    ~target: string=?,
    ~to: Path.t,
  ) => React.element = "Link"

  module Path = {
    @module("react-router") @react.component
    external make: (
      ~children: React.element=?,
      ~className: string=?,
      ~target: string=?,
      ~to: path,
    ) => React.element = "Link"
  }

  module String = {
    @module("react-router") @react.component
    external make: (
      ~children: React.element=?,
      ~className: string=?,
      ~target: string=?,
      ~to: string,
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
}

module Mdx = {
  type attributes = {
    canonical: Path.t,
    category?: string,
    description?: string,
    metaTitle?: string,
    order?: int,
    path: string,
    section?: string,
    slug: string,
    title: string,
  }

  type t = {
    __raw: string,
    attributes: attributes,
  }

  @module("react-router-mdx/server")
  external routes: string => array<Routes.t> = "routes"

  type remarkPlugin

  type loadMdxOptions = {remarkPlugins?: array<remarkPlugin>}

  @module("react-router-mdx/server")
  external loadMdx: (FetchAPI.request, ~options: loadMdxOptions=?) => promise<t> = "loadMdx"

  @module("react-router-mdx/client")
  external useMdxAttributes: unit => attributes = "useMdxAttributes"

  @module("react-router-mdx/client")
  external useMdxComponent: (~components: {..}=?) => Jsx.component<'a> = "useMdxComponent"

  @module("react-router-mdx/server")
  external loadAllMdx: (~filterByPaths: array<string>=?) => promise<array<attributes>> =
    "loadAllMdx"

  @module("react-router-mdx/client")
  external useMdxFiles: unit => {..} = "useMdxFiles"

  @module("remark-gfm")
  external gfm: remarkPlugin = "default"
}
