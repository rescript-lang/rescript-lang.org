module GetServerSideProps = {
  module Req = {
    type t
  }

  module Res = {
    type t

    @send external setHeader: (t, string, string) => unit = "setHeader"
    @send external write: (t, string) => unit = "write"
    @send external end_: t => unit = "end"
  }

  // See: https://github.com/zeit/next.js/blob/canary/packages/next/types/index.d.ts
  type context<'props, 'params> = {
    params: 'params,
    query: Dict.t<string>,
    req: Req.t,
    res: Res.t,
  }

  type t<'props, 'params> = context<'props, 'params> => promise<{"props": 'props}>
}

module GetStaticProps = {
  // See: https://github.com/zeit/next.js/blob/canary/packages/next/types/index.d.ts
  type context<'props, 'params> = {
    params: 'params,
    query: Dict.t<string>,
    req: Nullable.t<'props>,
  }

  type t<'props, 'params> = context<'props, 'params> => promise<{"props": 'props}>
}

module GetStaticPaths = {
  // 'params: dynamic route params used in dynamic routing paths
  // Example: pages/[id].js would result in a 'params = { id: string }
  type path<'params> = {params: 'params}

  type return<'params> = {
    paths: array<path<'params>>,
    fallback: bool,
  }

  type t<'params> = unit => promise<return<'params>>
}

module Head = {
  @module("next/head") @react.component
  external make: (~children: React.element) => React.element = "default"
}

module Error = {
  @module("next/error") @react.component
  external make: (~statusCode: int, ~children: React.element) => React.element = "default"
}

module Dynamic = {
  type options = {
    ssr?: bool,
    loading?: unit => React.element,
  }

  @module("next/dynamic")
  external dynamic: (unit => promise<'a>, options) => 'a = "default"

  @val external import: string => promise<'a> = "import"
}
