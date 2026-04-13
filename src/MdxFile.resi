type fileData = {
  content: string,
  frontmatter: JSON.t,
}

/** Maps a URL pathname to an .mdx file path on disk.
 * e.g. `/blog/release-12-0-0` with ~dir="markdown-pages/blog" ~alias="blog"
 * → `markdown-pages/blog/release-12-0-0.mdx`
 */
let resolveFilePath: (string, ~dir: string, ~alias: string) => string

/** Read a file from disk and parse its frontmatter using MarkdownParser. */
let loadFile: string => promise<fileData>

/** Scan a directory recursively for .mdx files and return URL paths.
 * e.g. scanPaths(~dir="markdown-pages/blog", ~alias="blog")
 * → ["blog/release-12-0-0", "blog/archived/some-post", ...]
 */
let scanPaths: (~dir: string, ~alias: string) => array<string>

/** Compile raw MDX content into a function-body string using @mdx-js/mdx. */
let compileMdx: (
  string,
  ~filePath: string,
  ~remarkPlugins: array<Mdx.remarkPlugin>=?,
) => promise<CompiledMdx.t>

/** Scan all .mdx files in a directory, parse frontmatter only, and return
 * as Mdx.attributes with `path` and `slug` fields populated.
 * Replaces `react-router-mdx`'s `loadAllMdx`.
 */
let loadAllAttributes: (~dir: string) => promise<array<Mdx.attributes>>
