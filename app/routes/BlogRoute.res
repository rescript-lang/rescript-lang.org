type loaderData = {posts: array<BlogApi.post>, category: Blog.category}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let showArchived = request.url->String.includes("archived")
  let posts = async () =>
    (await Mdx.allMdx())->Mdx.filterMdxPages("blog")->Array.map(BlogLoader.transform)

  let posts: array<BlogApi.post> = (await posts())->Array.filter(post => {
    post.archived == showArchived
  })
  let data = {posts, category: showArchived ? Archived : All}

  data
}

@react.component
let default = () => {
  let {posts, category} = ReactRouter.useLoaderData()
  <>
    <title>
      {React.string(
        `${switch category {
          | All => "All Posts"
          | Archived => "Archived Posts"
          }} | ReScript Blog`,
      )}
    </title>
    <Blog posts category />
  </>
}
