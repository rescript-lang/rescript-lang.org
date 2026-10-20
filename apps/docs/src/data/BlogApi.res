// Blog paths are relative to markdown-pages/blog. Article routes preserve the
// filename and any archived/ prefix, removing only the .mdx extension.

type post = {
  path: string,
  archived: bool,
  frontmatter: BlogFrontmatter.t,
}

let blogPathToSlug = path => {
  path->String.replaceAll("\\", "/")->String.replaceRegExp(/\.mdx$/, "")
}

let mdxFiles = dir => {
  Node.Fs.readdirSync(dir)->Array.filter(path => Node.Path.extname(path) === ".mdx")
}

let getAllPosts = () => {
  let postsDirectory = Node.Path.join2(Node.Process.cwd(), "markdown-pages/blog")
  let archivedPostsDirectory = Node.Path.join2(postsDirectory, "archived")

  let nonArchivedPosts = mdxFiles(postsDirectory)->Array.map(path => {
    let {frontmatter} =
      Node.Path.join2(postsDirectory, path)->Node.Fs.readFileSync->MarkdownParser.parseSync
    switch BlogFrontmatter.decode(frontmatter) {
    | Error(msg) => JsError.throwWithMessage(msg)
    | Ok(d) => {
        path,
        frontmatter: d,
        archived: false,
      }
    }
  })

  let archivedPosts = mdxFiles(archivedPostsDirectory)->Array.map(path => {
    let {frontmatter} =
      Node.Path.join2(archivedPostsDirectory, path)->Node.Fs.readFileSync->MarkdownParser.parseSync
    switch BlogFrontmatter.decode(frontmatter) {
    | Error(msg) => JsError.throwWithMessage(msg)
    | Ok(d) => {
        path: Node.Path.join2("archived", path),
        frontmatter: d,
        archived: true,
      }
    }
  })

  Array.concat(nonArchivedPosts, archivedPosts)->Array.toSorted((a, b) =>
    b.frontmatter.date->DateStr.toUTCDate->Date.getTime -.
      a.frontmatter.date->DateStr.toUTCDate->Date.getTime
  )
}

module RssFeed = {
  type item = {
    title: string,
    href: string,
    description: string,
    pubDate: Date.t,
  }

  // Retrieves the most recent [max] blog post feed items
  let getLatest = (~max=10, ~baseUrl="https://rescript-lang.org", ()): array<item> => {
    let items =
      getAllPosts()
      ->Array.slice(~start=0, ~end=max)
      ->Array.map(post => {
        let fm = post.frontmatter
        let description = fm.description->Nullable.getOr("")
        {
          title: fm.title,
          href: baseUrl ++ "/blog/" ++ blogPathToSlug(post.path),
          description,
          pubDate: DateStr.toUTCDate(fm.date),
        }
      })
    items
  }

  let toXmlString = (~siteTitle="ReScript Blog", ~siteDescription="", items: array<item>) => {
    let latestPubDateElement =
      items[0]
      ->Option.map(item => {
        let latestPubDateStr = item.pubDate->Date.toUTCString
        `<lastBuildDate>${latestPubDateStr}</lastBuildDate>`
      })
      ->Option.getOr("")

    let itemsStr =
      items
      ->Array.map(({title, pubDate, description, href}) => {
        let descriptionElement = switch description {
        | "" => ""
        | desc =>
          `<description>
            <![CDATA[${desc}]]>
          </description>`
        }

        let dateStr = pubDate->Date.toUTCString
        `
        <item>
          <title> <![CDATA[${title}]]></title>
          <link> ${href} </link>
          <guid> ${href} </guid>
          ${descriptionElement}
          <pubDate>${dateStr}</pubDate>
        </item>`
      })
      ->Array.join("\n")

    let ret = `<?xml version="1.0" encoding="utf-8" ?>
  <rss version="2.0">
    <channel>
      <title>${siteTitle}</title>
      <link>https://rescript-lang.org</link>
      <description>${siteDescription}</description>
      <language>en</language>
      ${latestPubDateElement}
${itemsStr}
    </channel>
  </rss>`

    ret
  }
}
