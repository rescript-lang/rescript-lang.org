type loaderData = ApiDocs.props

/** Loads page content and navigation from the same published compiler dataset. */
@live
let loader: ReactRouter.Loader.t<loaderData>

@live
let default: unit => React.element
