type io
type processor
type plugin = processor => io

@unboxed
type pluginOrOption =
  | Plugin(plugin)
  | SlugOption({prefix: string})

@unboxed
type rec rehypePlugin =
  | Plugin(processor => io)
  | WithOptions(array<pluginOrOption>)

@module("rehype-slug") external slug: plugin = "default"
