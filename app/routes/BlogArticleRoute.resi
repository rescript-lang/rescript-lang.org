type loaderData = {
  content: string,
  blogPost: BlogApi.post,
  title: string,
}

let loader: ReactRouter.Loader.t<loaderData>

let default: unit => React.element
