type loaderData = {posts: array<BlogApi.post>, category: Blog.category}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let posts: array<BlogApi.post> = BlogLoader.posts()
  let data = {posts, category: All}
  data
}

@react.component
let default = () => {
  let {posts, category} = ReactRouter.useLoaderData()
  <Blog posts category />
}
