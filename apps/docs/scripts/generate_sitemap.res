let rec collectPagePaths = (dirPath, urlPath) => {
  Node.Fs.readdirSync(dirPath)->Array.flatMap(entry => {
    let fullPath = Node.Path.join2(dirPath, entry)
    let stats = Node.Fs.statSync(fullPath)

    if stats["isDirectory"]() {
      let nextUrlPath = if urlPath === "" {
        entry
      } else {
        urlPath ++ "/" ++ entry
      }

      collectPagePaths(fullPath, nextUrlPath)
    } else if entry === "index.html" {
      [urlPath === "" ? "/" : "/" ++ urlPath]
    } else {
      []
    }
  })
}

let outputDirs = {
  let args = Node.Process.argv->Array.slice(~start=2)

  switch args->Array.length {
  | 0 => ["build/client"]
  | _ => args
  }
}

let sourceDir = outputDirs->Array.get(0)->Option.getOr("build/client")

if !Node.Fs.existsSync(sourceDir) {
  Console.error(`Cannot generate sitemap: ${sourceDir} does not exist`)
  Node.Process.exit(1)
}

let baseUrl = Node.Process.env->Dict.get("VITE_DEPLOYMENT_URL")->Option.getOr("")
let sitemap = sourceDir->collectPagePaths("")->Sitemap.render(~baseUrl)

outputDirs->Array.forEach(outputDir => {
  if Node.Fs.existsSync(outputDir) {
    let filePath = Node.Path.join2(outputDir, "sitemap.xml")
    Node.Fs.writeFileSync(filePath, sitemap, ~encoding="utf8")
    Console.log(`Generated ${filePath}`)
  }
})
