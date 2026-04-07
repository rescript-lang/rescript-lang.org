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
  relativePath->String.replaceAll("\\", "/") ++ ".mdx"
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

type sidebarEntry = {
  title: string,
  slug: option<string>,
  section: option<string>,
  order: option<int>,
  path: option<string>,
}

let jsonToString = json =>
  switch json {
  | JSON.String(s) => Some(s)
  | _ => None
  }

let jsonToInt = json =>
  switch json {
  | JSON.Number(n) => Some(Float.toInt(n))
  | _ => None
  }

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

      {
        title: dict->Dict.get("title")->Option.flatMap(jsonToString)->Option.getOr(""),
        slug: Some(Node.Path.basename(relativePath)),
        section: dict->Dict.get("section")->Option.flatMap(jsonToString),
        order: dict->Dict.get("order")->Option.flatMap(jsonToInt),
        path: Some(fullPath),
      }
    }),
  )
}
