type fileData = {
  content: string,
  frontmatter: JSON.t,
}

let resolveFilePath = (pathname, ~dir, ~alias) => {
  let path = if pathname->String.startsWith("/") {
    pathname->String.slice(~start=1, ~end=String.length(pathname))
  } else {
    pathname
  }
  let relativePath = path->String.replace(alias, dir)
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
