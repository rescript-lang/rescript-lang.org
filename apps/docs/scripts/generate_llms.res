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

let removeFileIfExists = (filePath: string): unit => {
  if Node.Fs.existsSync(filePath) {
    Node.Fs.unlinkSync(filePath)
  }
}

let writeTextFile = (filePath: string, content: string): unit => {
  Node.Fs.writeFileSync(filePath, content, ~encoding="utf8")
}

let copyFile = (sourcePath: string, targetPath: string): unit => {
  writeTextFile(targetPath, readMarkdownFile(sourcePath))
}

let removeLlmsTextFiles = (~llmsDirectory: string): unit => {
  removeFileIfExists(llmsDirectory->Node.Path.join2("llms.txt"))
  removeFileIfExists(llmsDirectory->Node.Path.join2("llm-full.txt"))
  removeFileIfExists(llmsDirectory->Node.Path.join2("llm-small.txt"))
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

let replaceVersionPlaceholder = (content: string, version: string): string => {
  let regex = RegExp.fromString("<VERSION>", ~flags="g")
  String.replaceRegExp(content, regex, version)
}

let createLlmsFiles = (
  ~version: string,
  ~txtFilePath: string,
  docsDirectory: string,
  llmsDirectory: string,
): unit => {
  let mdxFileTemplatePath = llmsDirectory->Node.Path.join2("template.mdx")
  let mdxFilePath = docsDirectory->Node.Path.join2("llms.mdx")
  let txtFileTemplatePath = llmsDirectory->Node.Path.join2("template.txt")

  Console.log(txtFilePath)

  writeTextFile(
    mdxFilePath,
    readMarkdownFile(mdxFileTemplatePath)->replaceVersionPlaceholder(version),
  )

  writeTextFile(
    txtFilePath,
    readMarkdownFile(txtFileTemplatePath)->replaceVersionPlaceholder(version),
  )
}

let copyCurrentFilesToVersion = (
  ~version: string,
  ~llmsDirectory: string,
  ~fullFilePath: string,
  ~smallFilePath: string,
  ~txtFilePath: string,
): unit => {
  let versionedLlmsDirectory = llmsDirectory->Node.Path.join2(version)

  createDirectoryIfNotExists(versionedLlmsDirectory)
  copyFile(txtFilePath, versionedLlmsDirectory->Node.Path.join2("llms.txt"))
  copyFile(fullFilePath, versionedLlmsDirectory->Node.Path.join2("llm-full.txt"))
  copyFile(smallFilePath, versionedLlmsDirectory->Node.Path.join2("llm-small.txt"))
}

let generateFile = (
  ~currentVersion: string,
  ~txtFilePath: string,
  ~staleTxtFilePath: option<string>=?,
  ~staleVersion: option<string>=?,
  docsDirectory: string,
  llmsDirectory: string,
): unit => {
  let fullFileName = "llm-full.txt"
  let smallFileName = "llm-small.txt"

  let llmsDir = llmsDirectory
  let fullFilePath = llmsDir->Node.Path.join2(fullFileName)
  let smallFilePath = llmsDir->Node.Path.join2(smallFileName)

  createDirectoryIfNotExists(llmsDir)
  clearFile(fullFilePath)
  clearFile(smallFilePath)

  switch staleTxtFilePath {
  | Some(filePath) => removeFileIfExists(filePath)
  | None => ()
  }

  switch staleVersion {
  | Some(version) => removeLlmsTextFiles(~llmsDirectory=llmsDirectory->Node.Path.join2(version))
  | None => ()
  }

  createLlmsFiles(~version=currentVersion, ~txtFilePath, docsDirectory, llmsDirectory)

  docsDirectory
  ->collectFiles
  ->Array.forEach(filePath => {
    if String.endsWith(filePath, ".mdx") {
      let content = readMarkdownFile(filePath)

      content->createFullFile(fullFilePath)

      content->createSmallFile(smallFilePath)
    }
  })

  copyCurrentFilesToVersion(
    ~version=currentVersion,
    ~llmsDirectory,
    ~fullFilePath,
    ~smallFilePath,
    ~txtFilePath,
  )
}

let currentManualVersion = "v12"
let currentReactVersion = "v0.14.2"

let manualDocsDirectory = "markdown-pages/docs/manual"
let reactDocsDirectory = "markdown-pages/docs/react"

let manualLlmsDirectory = "public/llms/manual"
let reactLlmsDirectory = "public/llms/react"

generateFile(
  ~currentVersion=currentManualVersion,
  ~txtFilePath="public/llms.txt",
  ~staleTxtFilePath="public/llms/manual/llms.txt",
  manualDocsDirectory,
  manualLlmsDirectory,
)
generateFile(
  ~currentVersion=currentReactVersion,
  ~txtFilePath=reactLlmsDirectory->Node.Path.join2("llms.txt"),
  ~staleVersion="latest",
  reactDocsDirectory,
  reactLlmsDirectory,
)
