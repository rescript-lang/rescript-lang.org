let transform = (mdx: Mdx.attributes): BlogApi.post => {
  // Archived posts are those in the archived folder
  let archived = switch mdx.slug {
      // The path isn't included in the mdx attributes when we are rending a post vs listing them
  | Some(slug) => slug->String.includes("/archived/")
  | None => false
  }
  {
    // The path isn't included in the mdx attributes when we are rending a post vs listing them
    path: mdx.slug->Option.getOr("/blog"),
    archived,
    frontmatter: {
      author: BlogFrontmatter.authors
      ->Array.find(author => author.username->String.includes(mdx.author))
      ->Option.getOrThrow, // TODO: this is probably unsafe and needs to be fixed
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
