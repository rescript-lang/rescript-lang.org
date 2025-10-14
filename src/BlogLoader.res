let transform = (mdx: ReactRouter.Mdx.attributes): BlogApi.post => {
  {
    path: mdx.path,
    archived: mdx.archived->Nullable.getOr(false),
    frontmatter: {
      author: BlogFrontmatter.authors
      ->Array.find(author => author.username->String.includes(mdx.author))
      ->Option.getOrThrow, // TODO: this is probably unsafe and needs to be fixed
      co_authors: (mdx.co_authors :> array<BlogFrontmatter.author>),
      date: mdx.date,
      previewImg: mdx.previewImg->Null.map(img => {
        Console.log2("img", img)
        img
      }),
      articleImg: mdx.articleImg,
      title: mdx.title,
      badge: mdx.badge
      ->Nullable.map(badge => BlogFrontmatter.decodeBadge(badge))
      ->Nullable.toOption
      ->Null.fromOption,
      description: mdx.description->Null.fromOption,
    },
  }
}

let posts = () => MdxRoute.allMdx->MdxRoute.filterMdxPages("blog")->Array.map(transform)
