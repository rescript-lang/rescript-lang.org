let buildEntries = (raw: string) => {
  let markdownTree = Mdast.fromMarkdown(raw)
  let tocResult = Mdast.toc(markdownTree, {maxDepth: 2})

  let headers = Dict.make()
  Mdast.reduceHeaders(tocResult.map, headers)

  headers
  ->Dict.toArray
  ->Array.map(((header, url)): TableOfContents.entry => {
    header,
    href: (url :> string),
  })
  ->Array.slice(~start=2)
}
