// Structure defined by `scripts/extract-indices.js`
@module("index_data/v900_belt_api_index.json")
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
    {name: "Introduction", href: "/docs/manual/v9.0.0/api/belt"}
  },
]

let setNavs = [
  {
    open NavItem
    {name: "HashSet", href: "/docs/manual/v9.0.0/api/belt/hash-set"}
  },
  {name: "HashSetInt", href: "/docs/manual/v9.0.0/api/belt/hash-set-int"},
  {name: "HashSetString", href: "/docs/manual/v9.0.0/api/belt/hash-set-string"},
  {name: "Set", href: "/docs/manual/v9.0.0/api/belt/set"},
  {name: "SetDict", href: "/docs/manual/v9.0.0/api/belt/set-dict"},
  {name: "SetInt", href: "/docs/manual/v9.0.0/api/belt/set-int"},
  {name: "SetString", href: "/docs/manual/v9.0.0/api/belt/set-string"},
]

let mapNavs = [
  {
    open NavItem
    {name: "HashMap", href: "/docs/manual/v9.0.0/api/belt/hash-map"}
  },
  {name: "HashMapInt", href: "/docs/manual/v9.0.0/api/belt/hash-map-int"},
  {name: "HashMapString", href: "/docs/manual/v9.0.0/api/belt/hash-map-string"},
  {name: "Map", href: "/docs/manual/v9.0.0/api/belt/map"},
  {name: "MapDict", href: "/docs/manual/v9.0.0/api/belt/map-dict"},
  {name: "MapInt", href: "/docs/manual/v9.0.0/api/belt/map-int"},
  {name: "MapString", href: "/docs/manual/v9.0.0/api/belt/map-string"},
]

let mutableCollectionsNavs = [
  {
    open NavItem
    {name: "MutableMap", href: "/docs/manual/v9.0.0/api/belt/mutable-map"}
  },
  {name: "MutableMapInt", href: "/docs/manual/v9.0.0/api/belt/mutable-map-int"},
  {name: "MutableMapString", href: "/docs/manual/v9.0.0/api/belt/mutable-map-string"},
  {name: "MutableQueue", href: "/docs/manual/v9.0.0/api/belt/mutable-queue"},
  {name: "MutableSet", href: "/docs/manual/v9.0.0/api/belt/mutable-set"},
  {name: "MutableSetInt", href: "/docs/manual/v9.0.0/api/belt/mutable-set-int"},
  {name: "MutableSetString", href: "/docs/manual/v9.0.0/api/belt/mutable-set-string"},
  {name: "MutableStack", href: "/docs/manual/v9.0.0/api/belt/mutable-stack"},
]

let basicNavs = [
  {
    open NavItem
    {name: "Array", href: "/docs/manual/v9.0.0/api/belt/array"}
  },
  {name: "List", href: "/docs/manual/v9.0.0/api/belt/list"},
  {name: "Float", href: "/docs/manual/v9.0.0/api/belt/float"},
  {name: "Int", href: "/docs/manual/v9.0.0/api/belt/int"},
  {name: "Range", href: "/docs/manual/v9.0.0/api/belt/range"},
  {name: "Id", href: "/docs/manual/v9.0.0/api/belt/id"},
  {name: "Option", href: "/docs/manual/v9.0.0/api/belt/option"},
  {name: "Result", href: "/docs/manual/v9.0.0/api/belt/result"},
]

let sortNavs = [
  {
    open NavItem
    {name: "SortArray", href: "/docs/manual/v9.0.0/api/belt/sort-array"}
  },
  {name: "SortArrayInt", href: "/docs/manual/v9.0.0/api/belt/sort-array-int"},
  {name: "SortArrayString", href: "/docs/manual/v9.0.0/api/belt/sort-array-string"},
]

let utilityNavs = [
  {
    open NavItem
    {name: "Debug", href: "/docs/manual/v9.0.0/api/belt/debug"}
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

    let title = "Belt Stdlib"
    let version = "latest"

    <ApiLayout components title version activeToc categories breadcrumbs> children </ApiLayout>
  }
}

module Prose = {
  @react.component
  let make = (~children) => <Docs components=ApiMarkdown.default> children </Docs>
}
