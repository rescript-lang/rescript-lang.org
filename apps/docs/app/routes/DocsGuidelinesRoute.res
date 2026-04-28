type loaderData = {
  compiledMdx: CompiledMdx.t,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)
  let filePath = MdxFile.resolveFilePath(
    (pathname :> string),
    ~dir="markdown-pages/docs/guidelines",
    ~alias="docs/guidelines",
  )

  let raw = await Node.Fs.readFile(filePath, "utf-8")
  let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)

  let description = FrontmatterUtils.getField(frontmatter, "description")
  let title = FrontmatterUtils.getField(frontmatter, "title")

  let compiledMdx = await MdxFile.compileMdx(raw, ~filePath, ~remarkPlugins=Mdx.plugins)

  let entries = TocUtils.buildEntries(raw)

  {
    compiledMdx,
    entries,
    title: `${title} | ReScript Guidelines`,
    description,
    filePath,
  }
}

let default = () => {
  let {compiledMdx, entries, title, description, filePath} = ReactRouter.useLoaderData()

  let docsAppRoot = "apps/docs"
  let editHref = `https://github.com/rescript-lang/rescript-lang.org/blob/master/${docsAppRoot}/${filePath}`

  let categories: array<SidebarNav.Category.t> = []

  <>
    <Meta title description />
    <NavbarTertiary>
      <a
        href=editHref className="inline text-14 hover:underline text-fire" rel="noopener noreferrer"
      >
        {React.string("Edit")}
      </a>
    </NavbarTertiary>
    <DocsLayout categories activeToc={title, entries}>
      <div className="markdown-body">
        <MdxContent compiledMdx />
      </div>
    </DocsLayout>
  </>
}
