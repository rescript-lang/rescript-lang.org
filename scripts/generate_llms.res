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
  let regex = RegExp.fromString("<CodeTab.*?>[\\s\\S]*?</CodeTab>", ~flags="g")
  String.replaceRegExp(content, regex, "")
}

let removeCodeBlocks = (content: string): string => {
  let regex = RegExp.fromString("```[a-zA-Z]+\\s*[\\s\\S]*?```", ~flags="g")
  String.replaceRegExp(content, regex, "")
}

let removeFileTitle = (content: string): string => {
  let regex = RegExp.fromString("---\ntitle[\\s\\S]*?---", ~flags="g")
  String.replaceRegExp(content, regex, "")
}

let removeUnnecessaryBreaks = (content: string): string => {
  let regex = RegExp.fromString("^\n{2,}", ~flags="g")
  String.replaceRegExp(content, regex, "")
}

let removeToDos = (content: string): string => {
  let regex = RegExp.fromString("<!-- TODO[\\s\\S]*?-->", ~flags="g")
  String.replaceRegExp(content, regex, "")
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

// TODO: post RR7 - refactor to remove the version parameter, as it's unused
let createLlmsFiles = (_version: string, docsDirectory: string, llmsDirectory: string): unit => {
  let mdxFileTemplatePath = llmsDirectory->Node.Path.join2("template.mdx")
  let mdxFilePath = docsDirectory->Node.Path.join2("llms.mdx")
  let txtFileTemplatePath = llmsDirectory->Node.Path.join2("template.txt")
  let txtFilePath = llmsDirectory->Node.Path.join2("llms.txt")

  Node.Fs.writeFileSync(mdxFilePath, readMarkdownFile(mdxFileTemplatePath))

  Node.Fs.writeFileSync(txtFilePath, readMarkdownFile(txtFileTemplatePath))
}

let generateFile = (docsDirectory: string, llmsDirectory: string): unit => {
  let fullFileName = "llm-full.txt"
  let smallFileName = "llm-small.txt"

  let llmsDir = llmsDirectory
  let fullFilePath = llmsDir->Node.Path.join2(fullFileName)
  let smallFilePath = llmsDir->Node.Path.join2(smallFileName)

  createDirectoryIfNotExists(llmsDir)
  clearFile(fullFilePath)
  clearFile(smallFilePath)

  createLlmsFiles("v12", docsDirectory, llmsDirectory)

  docsDirectory
  ->collectFiles
  ->Array.forEach(filePath => {
    if String.endsWith(filePath, ".mdx") {
      let content = readMarkdownFile(filePath)

      content->createFullFile(fullFilePath)

      content->createSmallFile(smallFilePath)
    }
  })
}

let manualDocsDirectory = "markdown-pages/docs/manual"
let reactDocsDirectory = "markdown-pages/docs/react"

let manualLlmsDirectory = "public/llms/manual"
let reactLlmsDirectory = "public/llms/react"

generateFile(manualDocsDirectory, manualLlmsDirectory)
generateFile(reactDocsDirectory, reactLlmsDirectory)
