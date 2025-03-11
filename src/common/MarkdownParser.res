type t
type plugin
type vfile<'a> = {..} as 'a

external makePlugin: 'a => plugin = "%identity"

%%private(
  @module("unified") external make: unit => t = "unified"

  @module("remark-parse") external remarkParse: plugin = "default"
  @module("remark-gfm") external remarkGfm: plugin = "default"
  @module("remark-comment") external remarkComment: plugin = "default"
  @module("remark-frontmatter") external remarkFrontmatter: plugin = "default"
  @module("remark-stringify") external remarkStringify: plugin = "default"

  @send external use: (t, plugin) => t = "use"
  @send external useOptions: (t, plugin, array<{..}>) => t = "use"

  @send external processSync: (t, string) => vfile<'a> = "processSync"
  @send external toString: vfile<'a> => string = "toString"

  @module("vfile-matter") external vfileMatter: vfile<'a> => unit = "matter"
)

type result = {
  frontmatter: JSON.t,
  content: string,
}

%%private(
  let vfileMatterPlugin = makePlugin(_options => (_tree, vfile) => vfileMatter(vfile))

  let parser =
    make()
    ->use(remarkParse)
    ->use(remarkStringify)
    ->use(remarkGfm)
    ->use(remarkComment)
    ->useOptions(remarkFrontmatter, [{"type": "yaml", "marker": "-"}])
    ->use(vfileMatterPlugin)
)

let parseSync = content => {
  let vfile = parser->processSync(content)
  let frontmatter = (vfile["data"]["matter"] :> option<JSON.t>)
  let frontmatter = frontmatter->Option.getOr(JSON.Object(Dict.make()))
  let content = vfile->toString
  {frontmatter, content}
}
