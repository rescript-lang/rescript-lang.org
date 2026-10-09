type loaderData = ApiDocs.props

type rec apiItem = {
  id: string,
  kind: string,
  name: string,
  items?: array<apiItem>,
  docStrings: array<string>,
}

/** Loads API documentation after normalizing React Router data-request pathnames. */
@live
let loader: ReactRouter.Loader.t<loaderData>

@live
let default: unit => React.element
