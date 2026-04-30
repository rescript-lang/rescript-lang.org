let buildEntries = (raw: string) => {
  let markdownTree = Mdast.fromMarkdown(raw)
  let headingIds = Url.makeAnchorIdState()
  let entries: array<TableOfContents.entry> = []

  Mdast.visit(markdownTree, "heading", node => {
    if node["depth"] <= 2 {
      let header = Mdast.toString(node)
      entries->Array.push({
        header,
        href: "#" ++ Url.makeUniqueAnchorId(~state=headingIds, ~title=header),
      })
    }
  })

  entries->Array.slice(~start=2)
}
