type t
type tree
type plugin
type vfile<'a> = {..} as 'a

external makePlugin: 'a => plugin = "%identity"

@module("unified") external make: unit => t = "unified"
@module("unist-util-visit") external visit: (tree, string, {..} => unit) => unit = "visit"

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

type result = {
  frontmatter: JSON.t,
  content: string,
}

let vfileMatterPlugin = makePlugin(_options => (_tree, vfile) => vfileMatter(vfile))

let remarkReScriptPrelude = tree => {
  let prelude = ref("")

  visit(tree, "code", node =>
    if node["lang"] === "res prelude" {
      prelude := prelude.contents + "\n" + node["value"]
    }
  )

  if prelude.contents->String.trim !== "" {
    visit(tree, "code", node => {
      if node["lang"] === "res" {
        let metaString = switch node["meta"]->Nullable.make {
        | Value(value) => value
        | _ => ""
        }

        node["meta"] =
          metaString +
          JSON.stringifyAny(prelude.contents)->Option.mapOr("", prelude => " prelude=" + prelude)

        Console.log2("⇢ Added meta to code block:", node["meta"])
      }
    })
  }
}

let remarkReScriptPreludePlugin = makePlugin(_options =>
  (tree, _vfile) => remarkReScriptPrelude(tree)
)

let parser =
  make()
  ->use(remarkParse)
  ->use(remarkGfm)
  ->use(remarkComment)
  ->useOptions(remarkFrontmatter, [{"type": "yaml", "marker": "-"}])
  ->use(vfileMatterPlugin)
  ->use(remarkReScriptPreludePlugin)
  ->use(remarkStringify)

let parseSync = content => {
  let vfile = parser->processSync(content)
  let frontmatter = (vfile["data"]["matter"] :> option<JSON.t>)
  let frontmatter = frontmatter->Option.getOr(JSON.Object(Dict.make()))
  let content = vfile->toString
  {frontmatter, content}
}
