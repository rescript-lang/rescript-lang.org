type loaderData = {
  compiledMdx: CompiledMdx.t,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
  categories: array<SidebarNav.Category.t>,
}

let communityTableOfContents = async () => {
  let groups =
    (await MdxFile.loadAllAttributes(~dir="markdown-pages/community"))
    ->Mdx.filterMdxPages("community")
    ->Mdx.groupBySection
    ->Dict.mapValues(values =>
      values->Mdx.sortSection->SidebarHelpers.convertToNavItems("/community")
    )

  SidebarHelpers.getAllGroups(groups, ["Resources"])
}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)
  let filePath = MdxFile.resolveFilePath(
    (pathname :> string),
    ~dir="markdown-pages/community",
    ~alias="community",
  )

  let raw = await Node.Fs.readFile(filePath, "utf-8")
  let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)

  let description = FrontmatterUtils.getField(frontmatter, "description")
  let title = FrontmatterUtils.getField(frontmatter, "title")

  let compiledMdx = await MdxFile.compileMdx(raw, ~filePath, ~remarkPlugins=Mdx.plugins)

  let entries = TocUtils.buildEntries(raw)

  let categories = await communityTableOfContents()

  {
    compiledMdx,
    entries,
    title: `${title} | ReScript Community`,
    description,
    filePath,
    categories,
  }
}

let default = () => {
  let {compiledMdx, entries, filePath, categories} = ReactRouter.useLoaderData()

  let docsAppRoot = "apps/docs"
  let editHref = `https://github.com/rescript-lang/rescript-lang.org/blob/master/${docsAppRoot}/${filePath}`

  <>
    <CommunityLayout categories entries>
      <div className="markdown-body">
        <MdxContent compiledMdx />
      </div>
      <a
        href=editHref className="inline text-14 hover:underline text-fire" rel="noopener noreferrer"
      >
        {React.string("Edit")}
      </a>
    </CommunityLayout>
  </>
}
