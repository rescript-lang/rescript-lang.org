type loaderData = ApiDocs.props

type rec apiItem = {
  id: string,
  kind: string,
  name: string,
  items?: array<apiItem>,
  docStrings: array<string>,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
