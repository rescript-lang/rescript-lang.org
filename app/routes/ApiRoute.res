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
    ->Array.filter(segment => segment !== "Stdlib" && segment !== "Belt" && segment !== "Js"),
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

  let apiDocs = parseApi(await Node.Fs.readFile("./docs/api/stdlib.json", "utf-8"))

  let stdlibToc = apiDocs->Dict.get("stdlib")

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
        name: "Stdlib",
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
  let title = switch (segments[4], segments[5]) {
  | (Some(x), Some(y)) => `${x->String.capitalize}.${y->String.capitalize} | ReScript API`
  | (Some(x), None) => `${x->String.capitalize} | ReScript API`
  | _ => "ReScript API"
  }

  <>
    <title> {React.string(title)} </title>
    <ApiDocs {...loaderData} />
  </>
}
