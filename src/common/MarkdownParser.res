type t
type plugin
type ast<'a> = {..} as 'a

%%private(
  @module("unified") external make: unit => t = "unified"

  @module("remark-gfm") external remarkGfm: plugin = "default"
  @module("remark-comment") external remarkComment: plugin = "default"
  @module("remark-frontmatter") external remarkFrontmatter: plugin = "default"
  @module("remark-stringify") external remarkStringify: plugin = "default"

  @send external use: (t, plugin) => t = "use"
  @send external useOptions: (t, plugin, array<{..}>) => t = "use"

  @send external parse: (t, string) => ast<'a> = "parse"
  @send external runSync: (t, ast<'a>) => ast<'a> = "runSync"
  @send external stringify: (t, ast<'a>) => string = "stringify"
)

type result = {
  frontmatter: JSON.t,
  content: string,
}

%%private(
  let parser =
    make()
    ->use(remarkGfm)
    ->use(remarkComment)
    ->useOptions(remarkFrontmatter, [{"type": "yaml", "marker": "-"}])
    ->use(remarkStringify)
)

let parseSync = content => {
  let ast = parser->parse(content)
  let ast = parser->runSync(ast)
  let frontmatter = (ast["data"]["matter"] :> JSON.t)
  let content = parser->stringify(ast)
  {frontmatter, content}
}
