type loaderData = {
  compiledMdx: CompiledMdx.t,
  categories: array<SidebarNav.Category.t>,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
}

let guidesTableOfContents = async () => {
  let groups =
    (await MdxFile.loadAllAttributes(~dir="markdown-pages/docs"))
    ->Mdx.filterMdxPages("docs/guides")
    ->Mdx.groupBySection
    ->Dict.mapValues(values =>
      values->Mdx.sortSection->SidebarHelpers.convertToNavItems("/docs/guides")
    )

  SidebarHelpers.getAllGroups(groups, ["Overview", "Packages"])
}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)
  let filePath = MdxFile.resolveFilePath(
    (pathname :> string),
    ~dir="markdown-pages/docs/guides",
    ~alias="docs/guides",
  )

  let raw = await Node.Fs.readFile(filePath, "utf-8")
  let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)

  let description = FrontmatterUtils.getField(frontmatter, "description")
  let title = FrontmatterUtils.getField(frontmatter, "title")

  let categories = await guidesTableOfContents()

  let compiledMdx = await MdxFile.compileMdx(raw, ~filePath, ~remarkPlugins=Mdx.plugins)

  let entries = TocUtils.buildEntries(raw)

  {
    compiledMdx,
    categories,
    entries,
    title: `${title} | ReScript Guides`,
    description,
    filePath,
  }
}

let default = () => {
  let {compiledMdx, categories, entries, title, description, filePath} = ReactRouter.useLoaderData()

  let breadcrumbs = list{
    {Url.name: "Docs", href: "/docs/guides/overview"},
    {
      Url.name: "Guides",
      href: "/docs/guides/overview",
    },
  }

  let docsAppRoot = "apps/docs"
  let editHref = `https://github.com/rescript-lang/rescript-lang.org/blob/master/${docsAppRoot}/${filePath}`

  let activeToc = {TableOfContents.title, entries}

  <>
    <Meta title description />
    <NavbarTertiary sidebar={<DocsSidebar categories activeToc />}>
      <Breadcrumbs crumbs=breadcrumbs />
      <a
        href=editHref className="inline text-14 hover:underline text-fire" rel="noopener noreferrer"
      >
        {React.string("Edit")}
      </a>
    </NavbarTertiary>
    <DocsLayout categories activeToc docSearchLvl0="Guides">
      <div className="markdown-body">
        <MdxContent compiledMdx />
      </div>
    </DocsLayout>
  </>
}
