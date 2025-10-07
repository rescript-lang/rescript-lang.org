type loaderData = ApiDocs.props

let loader: ReactRouter.Loader.t<loaderData> = async args => {
  let pathname =
    WebAPI.URL.make(~url=args.request.url).pathname->String.replace("/docs/manual/api/", "")
  Console.log(pathname)

  let data = {
    await ApiDocs.getStaticProps(["stdlib", "bigint"])
  }

  data["props"]
}

let default = () => {
  let loaderData: loaderData = ReactRouter.useLoaderData()
  <ApiDocs {...loaderData} />
}
