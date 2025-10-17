module CommunityLayout = DocsLayout.Make({
  // Structure defined by `scripts/extract-tocs.js`
  @module("index_data/community_toc.json") external tocData: SidebarLayout.Toc.raw = "default"
})

@react.component
let make = (~frontmatter=?, ~components=MarkdownComponents.default, ~children) => {
  let breadcrumbs = list{{Url.name: "Community", href: "/community"}}

  <CommunityLayout
    theme=#Reason components metaTitleCategory="ReScript Community" breadcrumbs ?frontmatter
  >
    children
  </CommunityLayout>
}
