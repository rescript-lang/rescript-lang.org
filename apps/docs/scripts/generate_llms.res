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

let rec createDirectoryIfNotExists = (dirPath: string): unit => {
  if !Node.Fs.existsSync(dirPath) {
    let parentPath = Node.Path.dirname(dirPath)
    if parentPath !== "" && parentPath !== dirPath {
      createDirectoryIfNotExists(parentPath)
    }
    Node.Fs.mkdirSync(dirPath)
  }
}

type sectionLlmFile = {
  title: string,
  slug: string,
  section: string,
  description: string,
  excludedSlugs: array<string>,
}

type mdxDocument = {
  title: string,
  slug: string,
  section: string,
  order: option<float>,
  content: string,
}

let getFrontmatterString = (frontmatter: JSON.t, fieldName: string): string => {
  switch frontmatter {
  | Object(dict) =>
    switch dict->Dict.get(fieldName) {
    | Some(String(value)) => value
    | _ => ""
    }
  | _ => ""
  }
}

let getFrontmatterNumber = (frontmatter: JSON.t, fieldName: string): option<float> => {
  switch frontmatter {
  | Object(dict) =>
    switch dict->Dict.get(fieldName) {
    | Some(Number(value)) => Some(value)
    | _ => None
    }
  | _ => None
  }
}

let removeFrontmatter = (content: string): string => {
  let regex = RegExp.fromString("^---[\\s\\S]*?---\\s*", ~flags="")
  String.replaceRegExp(content, regex, "")
}

let readMdxDocument = (filePath: string): mdxDocument => {
  let rawContent = filePath->readMarkdownFile
  let {frontmatter}: MarkdownParser.result = rawContent->MarkdownParser.parseSync
  {
    title: frontmatter->getFrontmatterString("title"),
    slug: filePath->Node.Path.basename->String.replace(".mdx", ""),
    section: frontmatter->getFrontmatterString("section"),
    order: frontmatter->getFrontmatterNumber("order"),
    content: rawContent->removeFrontmatter->String.trim,
  }
}

let compareMdxDocuments = (a: mdxDocument, b: mdxDocument): float => {
  switch (a.order, b.order) {
  | (Some(orderA), Some(orderB)) =>
    switch Float.compare(orderA, orderB) {
    | 0. => String.compare(a.title, b.title)
    | result => result
    }
  | (Some(_), None) => -1.0
  | (None, Some(_)) => 1.0
  | (None, None) => String.compare(a.title, b.title)
  }
}

let sectionLlmFilePath = (~llmsDirectory: string, sectionFile: sectionLlmFile): string =>
  llmsDirectory->Node.Path.join2(sectionFile.slug)->Node.Path.join2("llm.txt")

let createSectionLlmFiles = (
  ~llmsDirectory: string,
  ~sectionFiles: array<sectionLlmFile>,
  ~documents: array<mdxDocument>,
): unit => {
  sectionFiles->Array.forEach(sectionFile => {
    let sectionDocuments =
      documents->Array.filter(document =>
        document.section === sectionFile.section &&
          !(sectionFile.excludedSlugs->Array.some(excludedSlug => excludedSlug === document.slug))
      )
    let content =
      sectionDocuments
      ->Array.map(document => document.content)
      ->Array.join("\n")
      ->String.trim

    let filePath = sectionLlmFilePath(~llmsDirectory, sectionFile)
    createDirectoryIfNotExists(Node.Path.dirname(filePath))
    writeTextFile(
      filePath,
      `# ${sectionFile.title}

${sectionFile.description}

${content}
`,
    )
  })
}

let removeSectionLlmFiles = (
  ~llmsDirectory: string,
  ~sectionFiles: array<sectionLlmFile>,
): unit => {
  sectionFiles->Array.forEach(sectionFile =>
    removeFileIfExists(sectionLlmFilePath(~llmsDirectory, sectionFile))
  )
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
  ~sectionFiles: array<sectionLlmFile>,
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
  sectionFiles->Array.forEach(sectionFile => {
    let sectionFilePath = sectionLlmFilePath(~llmsDirectory, sectionFile)
    let versionedSectionFilePath = sectionLlmFilePath(
      ~llmsDirectory=versionedLlmsDirectory,
      sectionFile,
    )
    createDirectoryIfNotExists(Node.Path.dirname(versionedSectionFilePath))
    copyFile(sectionFilePath, versionedSectionFilePath)
  })
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
  ~sectionFiles: array<sectionLlmFile>=[],
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

  staleVersions->Array.forEach(version => {
    let versionedLlmsDirectory = llmsDirectory->Node.Path.join2(version)
    removeLlmsTextFiles(~llmsDirectory=versionedLlmsDirectory)
    removeSectionLlmFiles(~llmsDirectory=versionedLlmsDirectory, ~sectionFiles)
  })

  createLlmsFiles(
    ~version=currentVersion,
    ~manualVersionLinks,
    ~rescriptReactVersion,
    ~reactVersion,
    ~txtFilePath,
    docsDirectory,
    llmsDirectory,
  )

  let mdxFilePaths =
    docsDirectory->collectFiles->Array.filter(filePath => String.endsWith(filePath, ".mdx"))

  mdxFilePaths->Array.forEach(filePath => {
    if String.endsWith(filePath, ".mdx") {
      let content = readMarkdownFile(filePath)

      content->createFullFile(fullFilePath)

      content->createSmallFile(smallFilePath)
    }
  })

  let documents = mdxFilePaths->Array.map(readMdxDocument)->Array.toSorted(compareMdxDocuments)

  createSectionLlmFiles(~llmsDirectory, ~sectionFiles, ~documents)

  copyVersions->Array.forEach(version =>
    copyCurrentFilesToVersion(
      ~version,
      ~llmsDirectory,
      ~fullFilePath,
      ~smallFilePath,
      ~sectionFiles,
      ~manualVersionLinks,
      ~rescriptReactVersion,
      ~reactVersion,
    )
  )
}

let currentManualVersion = "v12"
let manualMajorVersions = ["v12", "v13"]

let currentReactVersion = "v0.14.2"
let currentReactRuntimeVersion = "v19.2.4"

let manualSectionLlmFiles = [
  {
    title: "ReScript Language Overview",
    slug: "language-overview",
    section: "Language Features",
    description: "Focused documentation for ReScript syntax, data types, control flow, modules, and core language features.",
    excludedSlugs: [],
  },
  {
    title: "ReScript JavaScript Interop",
    slug: "javascript-interop",
    section: "JavaScript Interop",
    description: "Focused documentation for binding to JavaScript values, modules, functions, objects, JSON, TypeScript, and other runtime interop patterns.",
    excludedSlugs: [],
  },
  {
    title: "ReScript Build System",
    slug: "build-system",
    section: "Build System",
    description: "Focused documentation for ReScript build configuration, project structure, monorepo setup, compiler performance, and build-tool integration.",
    excludedSlugs: [],
  },
  {
    title: "ReScript Getting Started",
    slug: "getting-started",
    section: "Overview",
    description: "Focused documentation for installing ReScript, editor setup, migration notes, and onboarding from JavaScript.",
    excludedSlugs: ["llms"],
  },
]

let manualVersionLinks = `- [v13 pre-release LLMs index](https://rescript-lang.org/llms/manual/v13/llms.txt): The LLM file list for the latest ReScript v13 pre-release documentation
- [v13 pre-release complete documentation](https://rescript-lang.org/llms/manual/v13/llm-full.txt): The complete latest ReScript v13 pre-release documentation
- [v13 pre-release abridged documentation](https://rescript-lang.org/llms/manual/v13/llm-small.txt): A minimal latest ReScript v13 pre-release reference
- [v13 pre-release language overview](https://rescript-lang.org/llms/manual/v13/language-overview/llm.txt): Focused latest ReScript v13 pre-release language overview
- [v13 pre-release JavaScript interop](https://rescript-lang.org/llms/manual/v13/javascript-interop/llm.txt): Focused latest ReScript v13 pre-release JavaScript interop reference
- [v13 pre-release build system](https://rescript-lang.org/llms/manual/v13/build-system/llm.txt): Focused latest ReScript v13 pre-release build system reference
- [v13 pre-release getting started](https://rescript-lang.org/llms/manual/v13/getting-started/llm.txt): Focused latest ReScript v13 pre-release onboarding reference
- [v12 current LLMs index](https://rescript-lang.org/llms/manual/v12/llms.txt): The LLM file list for the current ReScript v12 documentation
- [v12 current complete documentation](https://rescript-lang.org/llms/manual/v12/llm-full.txt): The complete current ReScript v12 documentation
- [v12 current abridged documentation](https://rescript-lang.org/llms/manual/v12/llm-small.txt): A minimal current ReScript v12 reference
- [v12 current language overview](https://rescript-lang.org/llms/manual/v12/language-overview/llm.txt): Focused current ReScript v12 language overview
- [v12 current JavaScript interop](https://rescript-lang.org/llms/manual/v12/javascript-interop/llm.txt): Focused current ReScript v12 JavaScript interop reference
- [v12 current build system](https://rescript-lang.org/llms/manual/v12/build-system/llm.txt): Focused current ReScript v12 build system reference
- [v12 current getting started](https://rescript-lang.org/llms/manual/v12/getting-started/llm.txt): Focused current ReScript v12 onboarding reference`

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
  ~staleVersions=["v10", "v11"],
  ~sectionFiles=manualSectionLlmFiles,
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
