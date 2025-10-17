let transform = (mdx: Mdx.attributes): BlogApi.post => {
  let archived = switch mdx.archived {
  | Nullable.Value(archived) => archived
  | _ => false
  }
  {
    path: `${archived ? "archived/" : ""}${mdx.slug}`,
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
