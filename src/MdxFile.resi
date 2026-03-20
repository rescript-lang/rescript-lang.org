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
