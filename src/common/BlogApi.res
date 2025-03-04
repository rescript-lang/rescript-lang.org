// Same design as in the official nextjs blog starter template
// https://github.com/zeit/next.js/blob/canary/examples/blog-starter/lib/api.js

/*
    BlogApi gives access to the data within the _blogposts directory.

    The _blogposts content is treated as a flat directory. There is a
    set of whitelisted directories (for each category) to help declutter
    huge file masses.

    Every filename within _blogposts must be unique, even when nested in
    different directories. The filename will be sluggified, that means that e.g.
    for the filepath "_blogposts/compiler/2021-03-12-my-post.mdx", slug = "my-post"

    The reason for the flat hierarchy is that we want to keep a flat URL
    hierarchy with `https://rescript-lang.org/blog/[some-slug]`, without carrying
    over the full subdirectory hierarchy. This allows us to restructure
    internally more easily without breaking permalinks.

    This module offers functionality to query all slug information, and even
    gives access to fully parsed blog posts with frontmatter data etc.

    See `pages/blog.re` for more context on why we need this API.
 */

module GrayMatter = {
  type output = {
    data: JSON.t,
    content: string,
  }

  @module("gray-matter") external matter: string => output = "default"
}

type post = {
  path: string,
  archived: bool,
  frontmatter: BlogFrontmatter.t,
}

let blogPathToSlug = path => {
  path
  ->String.replaceRegExp(%re(`/^(archive\/)?\d\d\d\d-\d\d-\d\d-(.+)\.mdx$/`), "$2")
  ->String.replaceRegExp(%re(`/^(community\/)?\d\d\d\d-\d\d-\d\d-(.+)\.mdx$/`), "$2")
}

let mdxFiles = dir => {
  Node.Fs.readdirSync(dir)->Array.filter(path => Node.Path.extname(path) === ".mdx")
}

let getAllPosts = () => {
  let postsDirectory = Node.Path.join2(Node.Process.cwd(), "_blogposts")
  let archivedPostsDirectory = Node.Path.join2(postsDirectory, "archive")
  let communityPostsDirectory = Node.Path.join2(postsDirectory, "community")

  let nonArchivedPosts = mdxFiles(postsDirectory)->Array.map(path => {
    let {GrayMatter.data: data} =
      Node.Path.join2(postsDirectory, path)->Node.Fs.readFileSync->GrayMatter.matter
    switch BlogFrontmatter.decode(data) {
    | Error(msg) => Exn.raiseError(msg)
    | Ok(d) => {
        path,
        frontmatter: d,
        archived: false,
      }
    }
  })

  let archivedPosts = mdxFiles(archivedPostsDirectory)->Array.map(path => {
    let {GrayMatter.data: data} =
      Node.Path.join2(archivedPostsDirectory, path)->Node.Fs.readFileSync->GrayMatter.matter
    switch BlogFrontmatter.decode(data) {
    | Error(msg) => Exn.raiseError(msg)
    | Ok(d) => {
        path: Node.Path.join2("archive", path),
        frontmatter: d,
        archived: true,
      }
    }
  })

  let communityPosts = mdxFiles(communityPostsDirectory)->Array.map(path => {
    let {GrayMatter.data: data} =
      Node.Path.join2(communityPostsDirectory, path)->Node.Fs.readFileSync->GrayMatter.matter
    switch BlogFrontmatter.decode(data) {
    | Error(msg) => Exn.raiseError(msg)
    | Ok(d) => {
        path: Node.Path.join2("community", path),
        frontmatter: d,
        archived: false,
      }
    }
  })

  Array.concatMany(nonArchivedPosts, [archivedPosts, communityPosts])->Array.toSorted((a, b) =>
    String.compare(Node.Path.basename(b.path), Node.Path.basename(a.path))
  )
}

let getLivePosts = () => {
  let postsDirectory = Node.Path.join2(Node.Process.cwd(), "_blogposts")

  let livePosts = mdxFiles(postsDirectory)->Array.map(path => {
    let {GrayMatter.data: data} =
      Node.Path.join2(postsDirectory, path)->Node.Fs.readFileSync->GrayMatter.matter
    switch BlogFrontmatter.decode(data) {
    | Error(msg) => Exn.raiseError(msg)
    | Ok(d) => {
        path,
        frontmatter: d,
        archived: false,
      }
    }
  })

  livePosts->Array.toSorted((a, b) =>
    String.compare(Node.Path.basename(b.path), Node.Path.basename(a.path))
  )
}

let getSpecialPosts = directory => {
  let postsDirectory = Node.Path.join2(Node.Process.cwd(), "_blogposts")
  let specialPostsDirectory = Node.Path.join2(postsDirectory, directory)

  let specialPosts = mdxFiles(specialPostsDirectory)->Array.map(path => {
    let {GrayMatter.data: data} =
      Node.Path.join2(specialPostsDirectory, path)->Node.Fs.readFileSync->GrayMatter.matter
    switch BlogFrontmatter.decode(data) {
    | Error(msg) => Exn.raiseError(msg)
    | Ok(d) => {
        path: Node.Path.join2(directory, path),
        frontmatter: d,
        archived: directory === "archive",
      }
    }
  })

  specialPosts->Array.toSorted((a, b) =>
    String.compare(Node.Path.basename(b.path), Node.Path.basename(a.path))
  )
}

module RssFeed = {
  // Module inspired by
  // https://gist.github.com/fredrikbergqvist/36704828353ebf5379a5c08c7583fe2d

  // Example reference example for RSS 2.0:
  // http://static.userland.com/gems/backend/rssTwoExample2.xml

  // TODO:
  // In case the pubDate formatting doesn't work with toUTCString,
  // we can port something like this:
  // https://github.com/tjconcept/js-rfc822-date

  type item = {
    title: string,
    href: string,
    description: string,
    pubDate: Date.t,
  }

  // TODO: This is yet again a dirty approach to prevent UTC to substract too many
  //       hours of my local timezone so it does end up on another day, so we set the hours
  //       to 15 o clock. We need to reconsider the way we parse blog article dates,
  //       since the dates should always be parsed from a single timezone perspective
  let dateToUTCString = date => {
    date->Date.setHours(15)->ignore
    date->Date.toUTCString
  }

  // Retrieves the most recent [max] blog post feed items
  let getLatest = (~max=10, ~baseUrl="https://rescript-lang.org", ()): array<item> => {
    let items =
      getAllPosts()
      ->Array.map(post => {
        let fm = post.frontmatter
        let description = Null.toOption(fm.description)->Option.getOr("")
        {
          title: fm.title,
          href: baseUrl ++ "/blog/" ++ blogPathToSlug(post.path),
          description,
          pubDate: DateStr.toDate(fm.date),
        }
      })
      ->Array.slice(~start=0, ~end=max)
    items
  }

  let toXmlString = (~siteTitle="ReScript Blog", ~siteDescription="", items: array<item>) => {
    let latestPubDateElement =
      items[0]
      ->Option.map(item => {
        let latestPubDateStr = item.pubDate->dateToUTCString
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

        // TODO: convert pubdate to string
        let dateStr = pubDate->dateToUTCString
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
  </rss>` //rescript-lang.org</link>

    ret
  }
}
