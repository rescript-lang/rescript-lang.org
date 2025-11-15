let transform = (mdx: Mdx.attributes): BlogApi.post => {
  // Archived posts are those in the archived folder

  let archived =
    mdx.path
    ->Option.map(String.includes(_, "/archived/"))
    ->Option.getOr(false)

  {
    path: mdx.slug
    ->Option.map(slug => archived ? "archived/" ++ slug : slug)
    ->Option.getOr("/blog"),
    archived,
    frontmatter: {
      author: BlogFrontmatter.authors
      ->Array.find(author => author.username->String.includes(mdx.author))
      ->Option.getOr({
        // Fallback to the ReScript Team if we can't find a matching author
        username: "rescript-team",
        fullname: "ReScript Team",
        role: "Core Development",
        imgUrl: "https://pbs.twimg.com/profile_images/1358354824660541440/YMKNWE1V_400x400.png",
        social: X("rescriptlang"),
      }),
      co_authors: (mdx.co_authors->Nullable.getOr([]) :> array<BlogFrontmatter.author>),
      date: mdx.date,
      previewImg: mdx.previewImg,
      articleImg: mdx.articleImg,
      title: mdx.title,
      badge: mdx.badge->Nullable.map(badge => BlogFrontmatter.decodeBadge(badge)),
      description: mdx.description,
    },
  }
}
