type post = {
  path: string,
  archived: bool,
  frontmatter: BlogFrontmatter.t,
}

let blogPathToSlug: string => string

module RssFeed: {
  type item = {
    title: string,
    href: string,
    description: string,
    pubDate: Date.t,
  }
  let getLatest: (~max: int=?, ~baseUrl: string=?, unit) => array<item>
  let toXmlString: (~siteTitle: string=?, ~siteDescription: string=?, array<item>) => string
}
