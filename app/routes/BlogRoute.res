type loaderData = {posts: array<BlogApi.post>, category: Blog.category}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let showArchived = request.url->String.includes("archived")
  let posts = async () =>
    (await Mdx.allMdx())
    ->Mdx.filterMdxPages("blog")
    ->Array.map(BlogLoader.transform)
    ->Array.toSorted((a, b) => {
      a.frontmatter.date->DateStr.toDate > b.frontmatter.date->DateStr.toDate ? -1.0 : 1.0
    })

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
    <Meta
      siteName="ReScript Blog"
      title={`${switch category {
        | All => "All Posts"
        | Archived => "Archived Posts"
        }} | ReScript Blog`}
      description="News, Announcements, Release Notes and more"
    />

    <Blog posts category />
  </>
}
