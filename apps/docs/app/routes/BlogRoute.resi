type loaderData = {posts: array<BlogApi.post>, category: Blog.category}

@live
let loader: ReactRouter.Loader.t<loaderData>

@react.component @live
let default: unit => React.element
