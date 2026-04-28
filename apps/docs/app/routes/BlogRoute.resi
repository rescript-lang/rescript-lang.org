type loaderData = {posts: array<BlogApi.post>, category: Blog.category}

let loader: ReactRouter.Loader.t<loaderData>

@react.component
let default: unit => React.element
