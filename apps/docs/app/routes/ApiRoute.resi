type loaderData = ApiDocs.props

type rec apiItem = {
  id: string,
  kind: string,
  name: string,
  items?: array<apiItem>,
  docStrings: array<string>,
}

/** Loads API documentation after normalizing React Router data-request pathnames. */
let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
