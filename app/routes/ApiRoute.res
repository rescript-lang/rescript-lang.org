type loaderData = ApiDocs.props

type rec apiItem = {
  id: string,
  kind: string,
  name: string,
  items?: array<apiItem>,
  docStrings: array<string>,
}

let rec rawApiItemToNode = (apiItem: apiItem): ApiDocs.node => {
  {
    name: apiItem.name,
    path: apiItem.id
    ->String.split(".")
    ->Array.filter(segment =>
      segment !== "Stdlib" && segment !== "Belt" && segment !== "Js" && segment !== "Dom"
    ),
    children: apiItem.items
    ->Option.map(items =>
      Array.filter(items, item =>
        item.id
        ->String.split(".")
        ->Array.length > 3
      )->Array.map(rawApiItemToNode)
    )
    ->Option.getOr([]),
  }
}

@scope("JSON") @val
external parseApi: string => Dict.t<apiItem> = "parse"

let groupItems = apiDocs => {
  let parsedItems =
    apiDocs
    ->Dict.keysToArray
    ->Array.map(key => Dict.getUnsafe(apiDocs, key))
    ->Array.map(rawApiItemToNode)

  // Root items are the main submodules like Array, String, etc
  let rootItems = []

  // Child items are submodules to root items, such as Error.URIError, Error.TypeError, etc
  let childItems = []

  // a few children have their own children, e.g. Intl.NumberFormat
  // If we ever get 4 children deep this will need to be refactored
  let childrenOfChildren = []

  parsedItems->Array.forEach(node => {
    if node.path->Array.length < 2 {
      rootItems->Array.push(node)
    } else if node.path->Array.length > 2 {
      childrenOfChildren->Array.push(node)
    } else {
      childItems->Array.push(node)
    }
  })

  // attach the child items to their respective parents
  childItems->Array.forEach(node => {
    let parent = node.path[0]
    switch parent {
    | Some(parent) =>
      rootItems
      ->Array.find(item => item.name === parent)
      ->Option.forEach(parentNode => {
        parentNode.children->Array.push({...node, children: []})
      })
    | None => ()
    }
  })

  // attach the children of children to their respective parents
  childrenOfChildren->Array.forEach(node => {
    let parent = node.path[1]

    parent->Option.forEach(parentName => {
      let parentNode =
        rootItems->Array.find(item => item.children->Array.some(node => node.name === parentName))

      // TODO POST RR7: this can probably be refactored
      parentNode->Option.forEach(
        parentNode =>
          parentNode.children->Array.forEach(
            child => {
              if child.name === parentName {
                child.children->Array.push({...node, children: []})
              }
            },
          ),
      )
    })
  })

  rootItems
}

let loader: ReactRouter.Loader.t<loaderData> = async args => {
  let path =
    WebAPI.URL.make(~url=args.request.url).pathname
    ->String.replace("/docs/manual/api/", "")
    ->String.split("/")

  let basePath = path[0]->Option.getUnsafe

  let apiDocs = switch basePath {
  | "belt" => parseApi(await Node.Fs.readFile("./markdown-pages/docs/api/belt.json", "utf-8"))
  | "dom" => parseApi(await Node.Fs.readFile("./markdown-pages/docs/api/dom.json", "utf-8"))
  | _ => parseApi(await Node.Fs.readFile("./markdown-pages/docs/api/stdlib.json", "utf-8"))
  }

  let toctree = groupItems(apiDocs)

  let data = {
    // TODO POST RR7: refactor this function to only return the module and not the toctree
    // or move the toc logic to this function
    try {
      await ApiDocs.getStaticProps(path)
    } catch {
    | err => {"props": Error(JSON.stringifyAny(err)->Option.getOr("Error loading API data"))}
    }
  }

  data["props"]->Result.map((item): ApiDocs.api => {
    {
      module_: item.module_,
      toctree: {
        name: basePath->String.capitalize,
        path: [],
        children: toctree,
      },
    }
  })
}

let default = () => {
  let loaderData: loaderData = ReactRouter.useLoaderData()
  let {pathname} = ReactRouter.useLocation()

  let segments = (pathname :> string)->String.split("/")

  let _module = switch (segments[4], segments[5]) {
  | (Some(x), Some(y)) => Some(`${x->String.capitalize}.${y->String.capitalize}`)
  | (Some(x), None) => Some(`${x->String.capitalize}`)
  | _ => None
  }

  let title = switch _module {
  | Some(_module) => _module ++ " | ReScript API"
  | None => "ReScript API"
  }

  let docstrings =
    switch loaderData {
    | Ok(loaderData) => loaderData.module_.docstrings
    | Error(_) => []
    }
    ->Array.at(0)
    ->Option.flatMap(str => String.split(str, ".")[0])

  let breadcrumbs = {
    let prefix = {Url.name: "API", href: "/docs/manual/api"}
    let crumbs = ApiLayout.makeBreadcrumbs(~prefix, pathname)
    list{{Url.name: "Docs", href: "/docs/manual/api"}, ...crumbs}
  }

  let sidebarContent = switch loaderData {
  | Ok({toctree, module_: {items}}) =>
    <div>
      <div className="flex justify-between items-baseline px-4">
        <div className="flex flex-col text-fire font-medium">
          <VersionSelect />
        </div>
        <button
          className="flex items-center" onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}
        >
          <Icon.Close />
        </button>
      </div>
      <ApiDocs.SidebarTree node={toctree} items />
    </div>
  | Error(_) => React.null
  }

  <>
    <Meta title description=?docstrings />
    <NavbarSecondary />
    <NavbarTertiary sidebar=sidebarContent>
      <SidebarLayout.BreadCrumbs crumbs=breadcrumbs />
    </NavbarTertiary>
    <ApiDocs {...loaderData} />
  </>
}
