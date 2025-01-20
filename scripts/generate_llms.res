let readMarkdownFile = (filePath: string): string => {
  let fileContent = Node.Fs.readFileSync2(filePath, "utf8")
  fileContent
}

let rec collectFiles = (dirPath: string): array<string> => {
  let entries = Node.Fs.readdirSync(dirPath)
  entries->Array.reduce([], (acc, entry) => {
    let fullPath = Node.Path.join([dirPath, entry])
    let stats = Node.Fs.statSync(fullPath)
    switch stats["isDirectory"]() {
    | true => acc->Array.concat(collectFiles(fullPath))
    | false => {
        acc->Array.push(fullPath)
        acc
      }
    }
  })
}

let clearFile = (filePath: string): unit => {
  Node.Fs.writeFileSync(filePath, "")
}

let createDirectoryIfNotExists = (dirPath: string): unit => {
  if !Node.Fs.existsSync(dirPath) {
    Node.Fs.mkdirSync(dirPath)
  }
}

let removeCodeTabTags = (content: string): string => {
  let regex = Js.Re.fromStringWithFlags("<CodeTab.*?>[\\s\\S]*?</CodeTab>", ~flags="g")
  Js.String.replaceByRe(regex, "", content)
}

let removeCodeBlocks = (content: string): string => {
  let regex = Js.Re.fromStringWithFlags("```[a-zA-Z]+\\s*[\\s\\S]*?```", ~flags="g")
  Js.String.replaceByRe(regex, "", content)
}

let removeFileTitle = (content: string): string => {
  let regex = Js.Re.fromStringWithFlags("---\ntitle[\\s\\S]*?---", ~flags="g")
  Js.String.replaceByRe(regex, "", content)
}

let removeUnnecessaryBreaks = (content: string): string => {
  let regex = Js.Re.fromStringWithFlags("^\n{2,}", ~flags="g")
  Js.String.replaceByRe(regex, "", content)
}

let removeToDos = (content: string): string => {
  let regex = Js.Re.fromStringWithFlags("<!-- TODO[\\s\\S]*?-->", ~flags="g")
  Js.String.replaceByRe(regex, "", content)
}

let fillContentWithVersion = (content: string, version: string): string => {
  let regex = Js.Re.fromStringWithFlags("<VERSION>", ~flags="g")
  Js.String.replaceByRe(regex, version, content)
}

let createFullFile = (content: string, filePath: string): unit => {
  Node.Fs.appendFileSync(filePath, content ++ "\n", "utf8")
}

let createSmallFile = (content: string, filePath: string): unit => {
  let smallContent =
    content
    ->removeCodeTabTags
    ->removeFileTitle
    ->removeToDos
    ->removeCodeBlocks
    ->removeUnnecessaryBreaks
  Node.Fs.appendFileSync(filePath, smallContent, "utf8")
}

let createLlmsFiles = (version: string, docsDirectory: string, llmsDirectory: string): unit => {
  let mdxFileTemplatePath = llmsDirectory->Node.Path.join2("template.mdx")
  let mdxFilePath = docsDirectory->Node.Path.join2(version)->Node.Path.join2("llms.mdx")
  let txtFileTemplatePath = llmsDirectory->Node.Path.join2("template.txt")
  let txtFilePath = llmsDirectory->Node.Path.join2(version)->Node.Path.join2("llms.txt")

  Node.Fs.writeFileSync(
    mdxFilePath,
    readMarkdownFile(mdxFileTemplatePath)->fillContentWithVersion(version),
  )

  Node.Fs.writeFileSync(
    txtFilePath,
    readMarkdownFile(txtFileTemplatePath)->fillContentWithVersion(version),
  )
}

let processVersions = (
  versions: array<string>,
  docsDirectory: string,
  llmsDirectory: string,
): unit => {
  let fullFileName = "llm-full.txt"
  let smallFileName = "llm-small.txt"

  versions->Array.forEach(version => {
    let versionDir = docsDirectory->Node.Path.join2(version)
    let llmsDir = llmsDirectory->Node.Path.join2(version)
    let fullFilePath = llmsDir->Node.Path.join2(fullFileName)
    let smallFilePath = llmsDir->Node.Path.join2(smallFileName)

    createDirectoryIfNotExists(llmsDir)
    clearFile(fullFilePath)
    clearFile(smallFilePath)

    createLlmsFiles(version, docsDirectory, llmsDirectory)

    versionDir
    ->collectFiles
    ->Array.forEach(filePath => {
      if Js.String.endsWith(".mdx", filePath) {
        let content = readMarkdownFile(filePath)

        content->createFullFile(fullFilePath)

        content->createSmallFile(smallFilePath)
      }
    })
  })
}

let manualVersions = ["v12.0.0", "v11.0.0"]
let reactManualVersions = ["latest", "v0.10.0", "v0.11.0"]

let manualDocsDirectory = "pages/docs/manual"
let reactDocsDirectory = "pages/docs/react"

let manualLlmsDirectory = "public/llms/manual"
let reactLlmsDirectory = "public/llms/react"

processVersions(manualVersions, manualDocsDirectory, manualLlmsDirectory)
processVersions(reactManualVersions, reactDocsDirectory, reactLlmsDirectory)