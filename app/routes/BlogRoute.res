type loaderData = {posts: array<BlogApi.post>, category: Blog.category}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let showArchived = request.url->String.includes("archived")
  let posts: array<BlogApi.post> = MdxRoute.posts()->Array.filter(post => {
    post.archived == showArchived
  })
  let data = {posts, category: All}
  data
}

@react.component
let default = () => {
  let {posts, category} = ReactRouter.useLoaderData()
  <Blog posts category />
}
