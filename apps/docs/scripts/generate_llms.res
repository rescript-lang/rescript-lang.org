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

let replacePlaceholder = (content: string, placeholder: string, value: string): string => {
  let regex = RegExp.fromString(placeholder, ~flags="g")
  String.replaceRegExp(content, regex, value)
}

let manualVersionLabel = (version: string): string => {
  switch version {
  | "v12" => "v12 (current version)"
  | "v13" => "v13 (pre-release version)"
  | version => version
  }
}

let renderTemplate = (
  content: string,
  ~version: string,
  ~manualVersionLinks: string,
  ~rescriptReactVersion: string,
  ~reactVersion: string,
): string => {
  content
  ->replacePlaceholder("<VERSION>", version)
  ->replacePlaceholder("<MANUAL_VERSION_LABEL>", version->manualVersionLabel)
  ->replacePlaceholder("<MANUAL_VERSION_LINKS>", manualVersionLinks)
  ->replacePlaceholder("<RESCRIPT_REACT_VERSION>", rescriptReactVersion)
  ->replacePlaceholder("<REACT_VERSION>", reactVersion)
}

let createLlmsFiles = (
  ~version: string,
  ~manualVersionLinks: string,
  ~rescriptReactVersion: string,
  ~reactVersion: string,
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
    readMarkdownFile(mdxFileTemplatePath)->renderTemplate(
      ~version,
      ~manualVersionLinks,
      ~rescriptReactVersion,
      ~reactVersion,
    ),
  )

  writeTextFile(
    txtFilePath,
    readMarkdownFile(txtFileTemplatePath)->renderTemplate(
      ~version,
      ~manualVersionLinks,
      ~rescriptReactVersion,
      ~reactVersion,
    ),
  )
}

let copyCurrentFilesToVersion = (
  ~version: string,
  ~llmsDirectory: string,
  ~fullFilePath: string,
  ~smallFilePath: string,
  ~manualVersionLinks: string,
  ~rescriptReactVersion: string,
  ~reactVersion: string,
): unit => {
  let versionedLlmsDirectory = llmsDirectory->Node.Path.join2(version)
  let txtFileTemplatePath = llmsDirectory->Node.Path.join2("template.txt")

  createDirectoryIfNotExists(versionedLlmsDirectory)
  writeTextFile(
    versionedLlmsDirectory->Node.Path.join2("llms.txt"),
    readMarkdownFile(txtFileTemplatePath)->renderTemplate(
      ~version,
      ~manualVersionLinks,
      ~rescriptReactVersion,
      ~reactVersion,
    ),
  )
  copyFile(fullFilePath, versionedLlmsDirectory->Node.Path.join2("llm-full.txt"))
  copyFile(smallFilePath, versionedLlmsDirectory->Node.Path.join2("llm-small.txt"))
}

let generateFile = (
  ~currentVersion: string,
  ~copyVersions: array<string>,
  ~manualVersionLinks: string,
  ~rescriptReactVersion: string,
  ~reactVersion: string,
  ~txtFilePath: string,
  ~staleTxtFilePath: option<string>=?,
  ~staleVersions: array<string>,
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

  staleVersions->Array.forEach(version =>
    removeLlmsTextFiles(~llmsDirectory=llmsDirectory->Node.Path.join2(version))
  )

  createLlmsFiles(
    ~version=currentVersion,
    ~manualVersionLinks,
    ~rescriptReactVersion,
    ~reactVersion,
    ~txtFilePath,
    docsDirectory,
    llmsDirectory,
  )

  docsDirectory
  ->collectFiles
  ->Array.forEach(filePath => {
    if String.endsWith(filePath, ".mdx") {
      let content = readMarkdownFile(filePath)

      content->createFullFile(fullFilePath)

      content->createSmallFile(smallFilePath)
    }
  })

  copyVersions->Array.forEach(version =>
    copyCurrentFilesToVersion(
      ~version,
      ~llmsDirectory,
      ~fullFilePath,
      ~smallFilePath,
      ~manualVersionLinks,
      ~rescriptReactVersion,
      ~reactVersion,
    )
  )
}

let currentManualVersion = "v12"
let manualMajorVersions = ["v11", "v12", "v13"]

let currentReactVersion = "v0.14.2"
let currentReactRuntimeVersion = "v19.2.4"

let manualVersionLinks = `- [v13 pre-release LLMs index](https://rescript-lang.org/llms/manual/v13/llms.txt): The LLM file list for the latest ReScript v13 pre-release documentation
- [v13 pre-release complete documentation](https://rescript-lang.org/llms/manual/v13/llm-full.txt): The complete latest ReScript v13 pre-release documentation
- [v13 pre-release abridged documentation](https://rescript-lang.org/llms/manual/v13/llm-small.txt): A minimal latest ReScript v13 pre-release reference
- [v12 current LLMs index](https://rescript-lang.org/llms/manual/v12/llms.txt): The LLM file list for the current ReScript v12 documentation
- [v12 current complete documentation](https://rescript-lang.org/llms/manual/v12/llm-full.txt): The complete current ReScript v12 documentation
- [v12 current abridged documentation](https://rescript-lang.org/llms/manual/v12/llm-small.txt): A minimal current ReScript v12 reference
- [v11 LLMs index](https://rescript-lang.org/llms/manual/v11/llms.txt): The LLM file list for the latest ReScript v11 documentation
- [v11 complete documentation](https://rescript-lang.org/llms/manual/v11/llm-full.txt): The complete latest ReScript v11 documentation
- [v11 abridged documentation](https://rescript-lang.org/llms/manual/v11/llm-small.txt): A minimal latest ReScript v11 reference`

let manualDocsDirectory = "markdown-pages/docs/manual"
let reactDocsDirectory = "markdown-pages/docs/react"

let manualLlmsDirectory = "public/llms/manual"
let reactLlmsDirectory = "public/llms/react"

generateFile(
  ~currentVersion=currentManualVersion,
  ~copyVersions=manualMajorVersions,
  ~manualVersionLinks,
  ~rescriptReactVersion="",
  ~reactVersion="",
  ~txtFilePath="public/llms.txt",
  ~staleTxtFilePath="public/llms/manual/llms.txt",
  ~staleVersions=["v10"],
  manualDocsDirectory,
  manualLlmsDirectory,
)
generateFile(
  ~currentVersion=currentReactVersion,
  ~copyVersions=[currentReactVersion],
  ~manualVersionLinks="",
  ~rescriptReactVersion=currentReactVersion,
  ~reactVersion=currentReactRuntimeVersion,
  ~txtFilePath=reactLlmsDirectory->Node.Path.join2("llms.txt"),
  ~staleVersions=["latest"],
  reactDocsDirectory,
  reactLlmsDirectory,
)
