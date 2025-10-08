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
    ->String.toLowerCase
    ->String.split(".")
    ->Array.filter(segment => segment !== "stdlib"),
    children: apiItem.items->Option.map(Array.map(_, rawApiItemToNode))->Option.getOr([]),
  }
}

@scope("JSON") @val
external parseApi: string => Dict.t<apiItem> = "parse"

let loader: ReactRouter.Loader.t<loaderData> = async args => {
  let path =
    WebAPI.URL.make(~url=args.request.url).pathname
    ->String.replace("/docs/manual/api/", "")
    ->String.split("/")

  let apiDocs = parseApi(await Node.Fs.readFile("./docs/api/stdlib.json", "utf-8"))

  let stdlibToc = apiDocs->Dict.get("stdlib")

  let toctree =
    apiDocs
    ->Dict.keysToArray
    ->Array.map(key => Dict.getUnsafe(apiDocs, key))
    ->Array.map(rawApiItemToNode)

  let data = {
    // TODO RR7: refactor this function to only return the module and not the toctree
    // or move the toc logic to this function
    await ApiDocs.getStaticProps(path)
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
  <ApiDocs {...loaderData} />
}
