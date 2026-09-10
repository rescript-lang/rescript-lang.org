let rec collectPagePaths = (dirPath, urlPath) => {
  NodeJs.Fs.readdirSync(dirPath)->Array.flatMap(entry => {
    let fullPath = NodeJs.Path.join2(dirPath, entry)
    let stats = NodeJs.Fs.statSync(fullPath)

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
  let args = NodeJs.Process.argv->Array.slice(~start=2)

  switch args->Array.length {
  | 0 => ["build/client"]
  | _ => args
  }
}

let sourceDir = outputDirs->Array.get(0)->Option.getOr("build/client")

if !NodeJs.Fs.existsSync(sourceDir) {
  Console.error(`Cannot generate sitemap: ${sourceDir} does not exist`)
  NodeJs.Process.exit(1)
}

let baseUrl = NodeJs.Process.env->Dict.get("VITE_DEPLOYMENT_URL")->Option.getOr("")
let sitemap = sourceDir->collectPagePaths("")->Sitemap.render(~baseUrl)

outputDirs->Array.forEach(outputDir => {
  if NodeJs.Fs.existsSync(outputDir) {
    let filePath = NodeJs.Path.join2(outputDir, "sitemap.xml")
    NodeJs.Fs.writeFileSync(filePath, sitemap, ~encoding="utf8")
    Console.log(`Generated ${filePath}`)
  }
})
