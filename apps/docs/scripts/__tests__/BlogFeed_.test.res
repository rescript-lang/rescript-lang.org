open ScriptTest

@val @scope("process") external chdir: string => unit = "chdir"

let fixture = (title, date) =>
  `---
author: rescript-team
title: ${title}
date: "${date}"
---
Article content.
`

let blogDirectory = async () => {
  let directory = await temporaryDirectory("blog-feed-")
  let blog = join([directory, "markdown-pages", "blog"])
  await mkdir(join([blog, "archived"]), {recursive: true})
  await write(join([blog, "z-old.mdx"]), fixture("Old post", "2019-11-28"))
  await write(join([blog, "a-new.mdx"]), fixture("New post", "2026-04-28"))
  await write(join([blog, "archived", "middle.mdx"]), fixture("Archived post", "2020-01-01"))
  directory
}

let latestFrom = (directory, ~max=10) => {
  let previousDirectory = cwd()
  chdir(directory)
  let items = try {
    BlogApi.RssFeed.getLatest(~max, ())
  } catch {
  | exn =>
    chdir(previousDirectory)
    throw(exn)
  }
  chdir(previousDirectory)
  items
}

test("RSS selects posts by publication date before applying the limit", async () => {
  let directory = await blogDirectory()
  let items = latestFrom(directory, ~max=2)
  expect(items->Array.map(item => item.title))->toStrictEqual(["New post", "Archived post"])
  expect(latestFrom(directory, ~max=0))->toStrictEqual([])
})

test("RSS links match article routes, including archived posts", async () => {
  let directory = await blogDirectory()
  let items = latestFrom(directory)
  expect(items->Array.map(item => item.href))->toStrictEqual([
    "https://rescript-lang.org/blog/a-new",
    "https://rescript-lang.org/blog/archived/middle",
    "https://rescript-lang.org/blog/z-old",
  ])
  let routes = MdxFile.scanPaths(~dir=join([directory, "markdown-pages", "blog"]), ~alias="blog")
  items->Array.forEach(item => {
    let route = item.href->String.replace("https://rescript-lang.org/", "")
    expect(routes->Array.includes(route))->toBe(true)
  })
})

test("blog slugs preserve route filenames and existing slugs", async () => {
  expect(BlogApi.blogPathToSlug("release-12-0-0.mdx"))->toBe("release-12-0-0")
  expect(BlogApi.blogPathToSlug("archived/whats-new-in-7-pt2.mdx"))->toBe(
    "archived/whats-new-in-7-pt2",
  )
  expect(BlogApi.blogPathToSlug("archived/2020-01-01-post.mdx"))->toBe("archived/2020-01-01-post")
  expect(BlogApi.blogPathToSlug("archived/middle"))->toBe("archived/middle")
  expect(BlogApi.blogPathToSlug("archived\\middle.mdx"))->toBe("archived/middle")
})

test("RSS dates use midnight UTC and XML serialization leaves dates unchanged", async () => {
  let directory = await blogDirectory()
  let items = latestFrom(directory)
  let before = items->Array.map(item => item.pubDate->Date.getTime)
  let xml = items->BlogApi.RssFeed.toXmlString
  expect(xml)->toContain("<lastBuildDate>Tue, 28 Apr 2026 00:00:00 GMT</lastBuildDate>")
  expect(xml)->toContain("<pubDate>Thu, 28 Nov 2019 00:00:00 GMT</pubDate>")
  expect(items->Array.map(item => item.pubDate->Date.getTime))->toStrictEqual(before)
  expect(items->BlogApi.RssFeed.toXmlString)->toBe(xml)
})

test("the current blog feed contains ten recent posts with existing routes", async () => {
  let items = BlogApi.RssFeed.getLatest()
  let routes = MdxFile.scanPaths(~dir="markdown-pages/blog", ~alias="blog")
  expect(items->Array.length)->toBe(10)
  items->Array.forEach(item => {
    expect(
      routes->Array.includes(item.href->String.replace("https://rescript-lang.org/", "")),
    )->toBe(true)
  })
})
