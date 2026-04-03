type fileData = {
  content: string,
  frontmatter: JSON.t,
}

type compileInput = {value: string, path: string}
type compileOptions = {
  outputFormat: string,
  remarkPlugins: array<Mdx.remarkPlugin>,
}
@module("@mdx-js/mdx")
external compile: (compileInput, compileOptions) => promise<CompiledMdx.compileResult> = "compile"

@module("remark-frontmatter") external remarkFrontmatter: Mdx.remarkPlugin = "default"

let compileMdx = async (content, ~filePath, ~remarkPlugins=[]) => {
  let compiled = await compile(
    {value: content, path: filePath},
    {
      outputFormat: "function-body",
      remarkPlugins: [remarkFrontmatter, ...remarkPlugins],
    },
  )
  compiled->CompiledMdx.fromCompileResult
}

let resolveFilePath = (pathname, ~dir, ~alias) => {
  let path = if pathname->String.startsWith("/") {
    pathname->String.slice(~start=1, ~end=String.length(pathname))
  } else {
    pathname
  }
  let relativePath = if path->String.startsWith(alias ++ "/") {
    let rest = path->String.slice(~start=String.length(alias) + 1, ~end=String.length(path))
    Node.Path.join2(dir, rest)
  } else if path->String.startsWith(alias) {
    let rest = path->String.slice(~start=String.length(alias), ~end=String.length(path))
    Node.Path.join2(dir, rest)
  } else {
    path
  }
  relativePath ++ ".mdx"
}

let loadFile = async filePath => {
  let raw = await Node.Fs.readFile(filePath, "utf-8")
  let {frontmatter, content}: MarkdownParser.result = MarkdownParser.parseSync(raw)
  {content, frontmatter}
}

// Recursively scan a directory for .mdx files
let rec scanDir = (baseDir, currentDir) => {
  let entries = Node.Fs.readdirSync(currentDir)
  entries->Array.flatMap(entry => {
    let fullPath = Node.Path.join2(currentDir, entry)
    if Node.Fs.statSync(fullPath)["isDirectory"]() {
      scanDir(baseDir, fullPath)
    } else if Node.Path.extname(entry) === ".mdx" {
      // Get the relative path from baseDir
      let relativePath =
        fullPath
        ->String.replaceAll("\\", "/")
        ->String.replace(baseDir->String.replaceAll("\\", "/") ++ "/", "")
        ->String.replace(".mdx", "")
      [relativePath]
    } else {
      []
    }
  })
}

let scanPaths = (~dir, ~alias) => {
  scanDir(dir, dir)->Array.map(relativePath => {
    alias ++ "/" ++ relativePath
  })
}

// Convert frontmatter JSON dict to Mdx.attributes
// This is the same unsafe approach as react-router-mdx — frontmatter YAML
// becomes a JS object that we type as Mdx.attributes. Fields not present
// in the frontmatter (e.g. blog-specific `author`, `date`) are undefined at
// runtime, which is fine because docs/community code never accesses them.
external dictToAttributes: Dict.t<JSON.t> => Mdx.attributes = "%identity"

let loadAllAttributes = async (~dir) => {
  let files = scanDir(dir, dir)
  await Promise.all(
    files->Array.map(async relativePath => {
      let fullPath = Node.Path.join2(dir, relativePath ++ ".mdx")->String.replaceAll("\\", "/")
      let raw = await Node.Fs.readFile(fullPath, "utf-8")
      let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)

      let dict = switch frontmatter {
      | Object(dict) => dict
      | _ => Dict.make()
      }

      // Add path and slug fields (same as react-router-mdx does)
      dict->Dict.set("path", JSON.String(fullPath))
      let slug = Node.Path.basename(relativePath)
      dict->Dict.set("slug", JSON.String(slug))

      dictToAttributes(dict)
    }),
  )
}
