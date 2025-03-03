// Structure defined by `scripts/extract-indices.js`
@module("index_data/v900_js_api_index.json")
external indexData: Dict.t<{
  "moduleName": string,
  "headers": array<{
    "name": string,
    "href": string,
  }>,
}> = "default"

module Category = SidebarLayout.Sidebar.Category
module NavItem = SidebarLayout.Sidebar.NavItem

let overviewNavs = [
  {
    open NavItem
    {name: "JS", href: "/docs/manual/v9.0.0/api/js"}
  },
]

let apiNavs = [
  {
    open NavItem
    {name: "Array2", href: "/docs/manual/v9.0.0/api/js/array-2"}
  },
  {name: "Array", href: "/docs/manual/v9.0.0/api/js/array"},
  {name: "Console", href: "/docs/manual/v9.0.0/api/js/console"},
  {name: "Date", href: "/docs/manual/v9.0.0/api/js/date"},
  {name: "Dict", href: "/docs/manual/v9.0.0/api/js/dict"},
  {name: "Exn", href: "/docs/manual/v9.0.0/api/js/exn"},
  {name: "Float", href: "/docs/manual/v9.0.0/api/js/float"},
  {name: "Global", href: "/docs/manual/v9.0.0/api/js/global"},
  {name: "Int", href: "/docs/manual/v9.0.0/api/js/int"},
  {name: "Json", href: "/docs/manual/v9.0.0/api/js/json"},
  {name: "List", href: "/docs/manual/v9.0.0/api/js/list"},
  {name: "Math", href: "/docs/manual/v9.0.0/api/js/math"},
  {name: "NullUndefined", href: "/docs/manual/v9.0.0/api/js/null-undefined"},
  {name: "Null", href: "/docs/manual/v9.0.0/api/js/null"},
  {name: "Nullable", href: "/docs/manual/v9.0.0/api/js/nullable"},
  {name: "Obj", href: "/docs/manual/v9.0.0/api/js/obj"},
  {name: "Option", href: "/docs/manual/v9.0.0/api/js/option"},
  {name: "Promise", href: "/docs/manual/v9.0.0/api/js/promise"},
  {name: "Re", href: "/docs/manual/v9.0.0/api/js/re"},
  {name: "Result", href: "/docs/manual/v9.0.0/api/js/result"},
  {name: "String2", href: "/docs/manual/v9.0.0/api/js/string-2"},
  {name: "String", href: "/docs/manual/v9.0.0/api/js/string"},
  {
    name: "TypedArrayArrayBuffer",
    href: "/docs/manual/v9.0.0/api/js/typed-array_array-buffer",
  },
  {
    name: "TypedArrayDataView",
    href: "/docs/manual/v9.0.0/api/js/typed-array_data-view",
  },
  {
    name: "TypedArrayFloat32Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array_float-32-array",
  },
  {
    name: "TypedArrayFloat64Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array_float-64-array",
  },
  {
    name: "TypedArrayInt8Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array_int-8-array",
  },
  {
    name: "TypedArrayInt16Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array_int-16-array",
  },
  {
    name: "TypedArrayInt32Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array_int-32-array",
  },
  {
    name: "TypedArrayTypeS",
    href: "/docs/manual/v9.0.0/api/js/typed-array_type-s",
  },
  {
    name: "TypedArrayUint8Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array_uint-8-array",
  },
  {
    name: "TypedArrayUint8ClampedArray",
    href: "/docs/manual/v9.0.0/api/js/typed-array_uint-8-clamped-array",
  },
  {
    name: "TypedArrayUint16Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array_uint-16-array",
  },
  {
    name: "TypedArrayUint32Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array_uint-32-array",
  },
  {
    name: "TypedArray2ArrayBuffer",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_array-buffer",
  },
  {
    name: "TypedArray2DataView",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_data-view",
  },
  {
    name: "TypedArray2Float32Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_float-32-array",
  },
  {
    name: "TypedArray2Float64Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_float-64-array",
  },
  {
    name: "TypedArray2Int8Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_int-8-array",
  },
  {
    name: "TypedArray2Int16Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_int-16-array",
  },
  {
    name: "TypedArray2Int32Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_int-32-array",
  },
  {
    name: "TypedArray2Uint8Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_uint-8-array",
  },
  {
    name: "TypedArray2Uint8ClampedArray",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_uint-8-clamped-array",
  },
  {
    name: "TypedArray2Uint16Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_uint-16-array",
  },
  {
    name: "TypedArray2Uint32Array",
    href: "/docs/manual/v9.0.0/api/js/typed-array-2_uint-32-array",
  },
  {name: "TypedArray2", href: "/docs/manual/v9.0.0/api/js/typed-array-2"},
  {name: "TypedArray", href: "/docs/manual/v9.0.0/api/js/typed-array"},
  {name: "Types", href: "/docs/manual/v9.0.0/api/js/types"},
  {name: "Undefined", href: "/docs/manual/v9.0.0/api/js/undefined"},
  {name: "Vector", href: "/docs/manual/v9.0.0/api/js/vector"},
]

let categories = [
  {
    open Category
    {name: "Overview", items: overviewNavs}
  },
  {name: "Submodules", items: apiNavs},
]

module Docs = {
  @react.component
  let make = (~components=ApiMarkdown.default, ~children) => {
    let router = Next.Router.useRouter()
    let route = router.route

    // Gather data for the CollapsibleSection
    let headers = {
      open Option
      Dict.get(indexData, route)
      ->map(data => data["headers"]->Array.map(header => (header["name"], "#" ++ header["href"])))
      ->getOr([])
    }

    let moduleName = {
      open Option
      Dict.get(indexData, route)->map(data => data["moduleName"])->getOr("?")
    }

    let url = route->Url.parse

    let version = url->Url.getVersionString

    let prefix = {
      open Url
      {name: "API", href: "/docs/manual/" ++ (version ++ "/api")}
    }

    let breadcrumbs = ApiLayout.makeBreadcrumbs(~prefix, route)
    let activeToc = {
      open SidebarLayout.Toc
      {
        title: moduleName,
        entries: Array.map(headers, ((name, href)) => {header: name, href}),
      }
    }

    let title = "JS Module"
    let version = "v9.0.0"

    let warnBanner = <ApiLayout.OldDocsWarning route version />

    <ApiLayout components title version activeToc categories breadcrumbs>
      warnBanner
      children
    </ApiLayout>
  }
}

module Prose = {
  @react.component
  let make = (~children) => <Docs components=ApiMarkdown.default> children </Docs>
}
