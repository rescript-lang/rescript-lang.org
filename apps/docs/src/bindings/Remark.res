type io
type processor
type plugin = processor => io

@unboxed
type pluginOrOption = Plugin(plugin)

@unboxed
type rec remarkPlugin =
  | Plugin(processor => io)
  | WithOptions(array<pluginOrOption>)

@module("remark-comment") external comment: plugin = "default"
@module("remark-gfm") external gfm: plugin = "default"
@module("remark-frontmatter") external frontmatter: plugin = "default"
