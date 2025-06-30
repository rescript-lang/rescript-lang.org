type indexData = dict<{"moduleName": string, "headers": array<{"name": string, "href": string}>}>

@module("index_data/v800_belt_api_index.json")
external belt_v8_data: indexData = "default"

@module("index_data/v900_belt_api_index.json")
external belt_v9_data: indexData = "default"

@module("index_data/v1000_belt_api_index.json")
external belt_v10_data: indexData = "default"

@module("index_data/v800_js_api_index.json")
external js_v8_data: indexData = "default"

@module("index_data/v900_js_api_index.json")
external js_v9_data: indexData = "default"

@module("index_data/v1000_belt_api_index.json")
external js_v10_data: indexData = "default"

@module("index_data/v800_dom_api_index.json")
external dom_v8_data: indexData = "default"

@module("index_data/v900_dom_api_index.json")
external dom_v9_data: indexData = "default"

@module("index_data/v1000_dom_api_index.json")
external dom_v10_data: indexData = "default"

let indexData = dict{
  "belt": dict{
    "v8.0.0": belt_v8_data,
    "v9.0.0": belt_v9_data,
    "v10.0.0": belt_v10_data,
  },
  "js": dict{
    "v8.0.0": js_v8_data,
    "v9.0.0": js_v9_data,
    "v10.0.0": js_v10_data,
  },
  "dom": dict{
    "v8.0.0": dom_v8_data,
    "v9.0.0": dom_v9_data,
    "v10.0.0": dom_v10_data,
  },
}

module Category = SidebarLayout.Sidebar.Category
module NavItem = SidebarLayout.Sidebar.NavItem

module BeltDocs = {
  let overviewNavs = [
    {
      open NavItem
      {name: "Introduction", href: "/docs/manual/<version>/api/belt"}
    },
  ]

  let setNavs = [
    {
      open NavItem
      {name: "HashSet", href: "/docs/manual/<version>/api/belt/hash-set"}
    },
    {name: "HashSetInt", href: "/docs/manual/<version>/api/belt/hash-set-int"},
    {name: "HashSetString", href: "/docs/manual/<version>/api/belt/hash-set-string"},
    {name: "Set", href: "/docs/manual/<version>/api/belt/set"},
    {name: "SetDict", href: "/docs/manual/<version>/api/belt/set-dict"},
    {name: "SetInt", href: "/docs/manual/<version>/api/belt/set-int"},
    {name: "SetString", href: "/docs/manual/<version>/api/belt/set-string"},
  ]

  let mapNavs = [
    {
      open NavItem
      {name: "HashMap", href: "/docs/manual/<version>/api/belt/hash-map"}
    },
    {name: "HashMapInt", href: "/docs/manual/<version>/api/belt/hash-map-int"},
    {name: "HashMapString", href: "/docs/manual/<version>/api/belt/hash-map-string"},
    {name: "Map", href: "/docs/manual/<version>/api/belt/map"},
    {name: "MapDict", href: "/docs/manual/<version>/api/belt/map-dict"},
    {name: "MapInt", href: "/docs/manual/<version>/api/belt/map-int"},
    {name: "MapString", href: "/docs/manual/<version>/api/belt/map-string"},
  ]

  let mutableCollectionsNavs = [
    {
      open NavItem
      {name: "MutableMap", href: "/docs/manual/<version>/api/belt/mutable-map"}
    },
    {name: "MutableMapInt", href: "/docs/manual/<version>/api/belt/mutable-map-int"},
    {name: "MutableMapString", href: "/docs/manual/<version>/api/belt/mutable-map-string"},
    {name: "MutableQueue", href: "/docs/manual/<version>/api/belt/mutable-queue"},
    {name: "MutableSet", href: "/docs/manual/<version>/api/belt/mutable-set"},
    {name: "MutableSetInt", href: "/docs/manual/<version>/api/belt/mutable-set-int"},
    {name: "MutableSetString", href: "/docs/manual/<version>/api/belt/mutable-set-string"},
    {name: "MutableStack", href: "/docs/manual/<version>/api/belt/mutable-stack"},
  ]

  let basicNavs = [
    {
      open NavItem
      {name: "Array", href: "/docs/manual/<version>/api/belt/array"}
    },
    {name: "List", href: "/docs/manual/<version>/api/belt/list"},
    {name: "Float", href: "/docs/manual/<version>/api/belt/float"},
    {name: "Int", href: "/docs/manual/<version>/api/belt/int"},
    {name: "Range", href: "/docs/manual/<version>/api/belt/range"},
    {name: "Id", href: "/docs/manual/<version>/api/belt/id"},
    {name: "Option", href: "/docs/manual/<version>/api/belt/option"},
    {name: "Result", href: "/docs/manual/<version>/api/belt/result"},
  ]

  let sortNavs = [
    {
      open NavItem
      {name: "SortArray", href: "/docs/manual/<version>/api/belt/sort-array"}
    },
    {name: "SortArrayInt", href: "/docs/manual/<version>/api/belt/sort-array-int"},
    {name: "SortArrayString", href: "/docs/manual/<version>/api/belt/sort-array-string"},
  ]

  let utilityNavs = [
    {
      open NavItem
      {name: "Debug", href: "/docs/manual/<version>/api/belt/debug"}
    },
  ]

  let categories = [
    {
      open Category
      {name: "Overview", items: overviewNavs}
    },
    {name: "Basics", items: basicNavs},
    {name: "Set", items: setNavs},
    {name: "Map", items: mapNavs},
    {name: "Mutable Collections", items: mutableCollectionsNavs},
    {name: "Sort Collections", items: sortNavs},
    {name: "Utilities", items: utilityNavs},
  ]
}

module DomDocs = {
  let overviewNavs = [
    {
      open NavItem
      {name: "Dom", href: "/docs/manual/<version>/api/dom"}
    },
  ]

  let moduleNavs = [
    {
      open NavItem
      {name: "Storage", href: "/docs/manual/<version>/api/dom/storage"}
    },
    {
      open NavItem
      {name: "Storage2", href: "/docs/manual/<version>/api/dom/storage2"}
    },
  ]

  let categories = [
    {
      open Category
      {name: "Overview", items: overviewNavs}
    },
    {name: "Submodules", items: moduleNavs},
  ]
}

module JsDocs = {
  let overviewNavs = [
    {
      open NavItem
      {name: "JS", href: "/docs/manual/<version>/api/js"}
    },
  ]

  let apiNavs = [
    {
      open NavItem
      {name: "Array2", href: "/docs/manual/<version>/api/js/array-2"}
    },
    {name: "Array", href: "/docs/manual/<version>/api/js/array"},
    {name: "Console", href: "/docs/manual/<version>/api/js/console"},
    {name: "Date", href: "/docs/manual/<version>/api/js/date"},
    {name: "Dict", href: "/docs/manual/<version>/api/js/dict"},
    {name: "Exn", href: "/docs/manual/<version>/api/js/exn"},
    {name: "Float", href: "/docs/manual/<version>/api/js/float"},
    {name: "Global", href: "/docs/manual/<version>/api/js/global"},
    {name: "Int", href: "/docs/manual/<version>/api/js/int"},
    {name: "Json", href: "/docs/manual/<version>/api/js/json"},
    {name: "List", href: "/docs/manual/<version>/api/js/list"},
    {name: "Math", href: "/docs/manual/<version>/api/js/math"},
    {name: "NullUndefined", href: "/docs/manual/<version>/api/js/null-undefined"},
    {name: "Null", href: "/docs/manual/<version>/api/js/null"},
    {name: "Nullable", href: "/docs/manual/<version>/api/js/nullable"},
    {name: "Obj", href: "/docs/manual/<version>/api/js/obj"},
    {name: "Option", href: "/docs/manual/<version>/api/js/option"},
    {name: "Promise", href: "/docs/manual/<version>/api/js/promise"},
    {name: "Re", href: "/docs/manual/<version>/api/js/re"},
    {name: "Result", href: "/docs/manual/<version>/api/js/result"},
    {name: "String2", href: "/docs/manual/<version>/api/js/string-2"},
    {name: "String", href: "/docs/manual/<version>/api/js/string"},
    {
      name: "TypedArrayArrayBuffer",
      href: "/docs/manual/<version>/api/js/typed-array_array-buffer",
    },
    {name: "TypedArrayDataView", href: "/docs/manual/<version>/api/js/typed-array_data-view"},
    {
      name: "TypedArrayFloat32Array",
      href: "/docs/manual/<version>/api/js/typed-array_float-32-array",
    },
    {
      name: "TypedArrayFloat64Array",
      href: "/docs/manual/<version>/api/js/typed-array_float-64-array",
    },
    {
      name: "TypedArrayInt8Array",
      href: "/docs/manual/<version>/api/js/typed-array_int-8-array",
    },
    {
      name: "TypedArrayInt16Array",
      href: "/docs/manual/<version>/api/js/typed-array_int-16-array",
    },
    {
      name: "TypedArrayInt32Array",
      href: "/docs/manual/<version>/api/js/typed-array_int-32-array",
    },
    {name: "TypedArrayTypeS", href: "/docs/manual/<version>/api/js/typed-array_type-s"},
    {
      name: "TypedArrayUint8Array",
      href: "/docs/manual/<version>/api/js/typed-array_uint-8-array",
    },
    {
      name: "TypedArrayUint8ClampedArray",
      href: "/docs/manual/<version>/api/js/typed-array_uint-8-clamped-array",
    },
    {
      name: "TypedArrayUint16Array",
      href: "/docs/manual/<version>/api/js/typed-array_uint-16-array",
    },
    {
      name: "TypedArrayUint32Array",
      href: "/docs/manual/<version>/api/js/typed-array_uint-32-array",
    },
    {
      name: "TypedArray2ArrayBuffer",
      href: "/docs/manual/<version>/api/js/typed-array-2_array-buffer",
    },
    {
      name: "TypedArray2DataView",
      href: "/docs/manual/<version>/api/js/typed-array-2_data-view",
    },
    {
      name: "TypedArray2Float32Array",
      href: "/docs/manual/<version>/api/js/typed-array-2_float-32-array",
    },
    {
      name: "TypedArray2Float64Array",
      href: "/docs/manual/<version>/api/js/typed-array-2_float-64-array",
    },
    {
      name: "TypedArray2Int8Array",
      href: "/docs/manual/<version>/api/js/typed-array-2_int-8-array",
    },
    {
      name: "TypedArray2Int16Array",
      href: "/docs/manual/<version>/api/js/typed-array-2_int-16-array",
    },
    {
      name: "TypedArray2Int32Array",
      href: "/docs/manual/<version>/api/js/typed-array-2_int-32-array",
    },
    {
      name: "TypedArray2Uint8Array",
      href: "/docs/manual/<version>/api/js/typed-array-2_uint-8-array",
    },
    {
      name: "TypedArray2Uint8ClampedArray",
      href: "/docs/manual/<version>/api/js/typed-array-2_uint-8-clamped-array",
    },
    {
      name: "TypedArray2Uint16Array",
      href: "/docs/manual/<version>/api/js/typed-array-2_uint-16-array",
    },
    {
      name: "TypedArray2Uint32Array",
      href: "/docs/manual/<version>/api/js/typed-array-2_uint-32-array",
    },
    {name: "TypedArray2", href: "/docs/manual/<version>/api/js/typed-array-2"},
    {name: "TypedArray", href: "/docs/manual/<version>/api/js/typed-array"},
    {name: "Types", href: "/docs/manual/<version>/api/js/types"},
    {name: "Undefined", href: "/docs/manual/<version>/api/js/undefined"},
    {name: "Vector", href: "/docs/manual/<version>/api/js/vector"},
  ]

  let categories = [
    {
      open Category
      {name: "Overview", items: overviewNavs}
    },
    {name: "Submodules", items: apiNavs},
  ]
}

module type Docs = {
  let categories: array<Category.t>
}

let makeCategories = (module_: module(Docs), version) => {
  let module(Docs) = module_
  Docs.categories->Array.map(({name, items}) => {
    let items = items->Array.map(item => {
      ...item,
      href: item.href->String.replace("<version>", version),
    })
    {Category.name, items}
  })
}

let moduleCategories = (moduleName, version) => {
  switch moduleName {
  | "belt" => makeCategories(module(BeltDocs), version)
  | "js" => makeCategories(module(JsDocs), version)
  | "dom" => makeCategories(module(DomDocs), version)
  | _ => []
  }
}

@react.component
let make = (~components=ApiMarkdown.default, ~version: Url.t, ~children) => {
  let router = Next.Router.useRouter()
  let route = router.route
  let versionStr = version->Url.getVersionString

  let warnBanner = <ApiLayout.OldDocsWarning route version=versionStr />

  switch version.pagepath->Array.get(1) {
  | None =>
    let title = "API"
    let categories: array<Category.t> = [
      {
        name: "Introduction",
        items: [{name: "Overview", href: `/docs/manual/${versionStr}/api`}],
      },
      {
        name: "Modules",
        items: [
          {name: "Js Module", href: `/docs/manual/${versionStr}/api/js`},
          {name: "Belt Stdlib", href: `/docs/manual/${versionStr}/api/belt`},
          {name: "Dom Module", href: `/docs/manual/${versionStr}/api/dom`},
        ],
      },
    ]
    <ApiLayout components categories title version=versionStr>
      warnBanner
      children
    </ApiLayout>
  | Some(moduleName) =>
    let indexData = switch Dict.get(indexData, moduleName) {
    | Some(moduleData) =>
      Dict.get(moduleData, version->Url.getVersionString)->Option.getOrThrow(
        ~message=`Not found data for ${moduleName} version ${versionStr}`,
      )
    | None => throw(Failure(`Not found index data for module: ${moduleName}`))
    }

    // Gather data for the CollapsibleSection
    let headers = {
      open Option
      Dict.get(indexData, route)
      ->map(data => data["headers"]->Array.map(header => (header["name"], "#" ++ header["href"])))
      ->getOr([])
    }

    let prefix = {
      open Url
      {name: "API", href: "/docs/manual/" ++ (versionStr ++ "/api")}
    }

    let breadcrumbs = ApiLayout.makeBreadcrumbs(~prefix, route)

    let activeToc = {
      open SidebarLayout.Toc
      {
        title: moduleName,
        entries: Array.map(headers, ((name, href)) => {header: name, href}),
      }
    }

    let categories = moduleCategories(moduleName, versionStr)

    let title = switch moduleName {
    | "belt" => "Belt Stdlib"
    | "js" => "Js Stdlib"
    | "dom" => "Dom Stdlib"
    | _ => assert(false)
    }

    <ApiLayout components title version={versionStr} activeToc categories breadcrumbs>
      warnBanner
      children
    </ApiLayout>
  }
}
