let transform = (mdx: ReactRouter.Mdx.attributes): BlogApi.post => {
  let archived = switch mdx.archived {
  | Nullable.Value(archived) => archived
  | _ => false
  }
  Console.log(mdx)
  {
    path: mdx.path,
    archived,
    frontmatter: {
      author: BlogFrontmatter.authors
      ->Array.find(author => author.username->String.includes(mdx.author))
      ->Option.getOrThrow, // TODO: this is probably unsafe and needs to be fixed
      co_authors: (mdx.co_authors :> array<BlogFrontmatter.author>),
      date: mdx.date,
      previewImg: mdx.previewImg,
      articleImg: mdx.articleImg,
      title: mdx.title,
      badge: mdx.badge->Nullable.map(badge => BlogFrontmatter.decodeBadge(badge)),
      description: mdx.description,
      slug: `/blog${archived ? "/archived" : ""}/${mdx.slug}`,
    },
  }
}

let posts = () => MdxRoute.allMdx->MdxRoute.filterMdxPages("blog")->Array.map(transform)
