type loaderData = {
  compiledMdx: CompiledMdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
}

// Build sidebar categories from all React docs, sorted by their "order" field in frontmatter
let reactTableOfContents = async () => {
  let groups =
    (await MdxFile.loadAllAttributes(~dir="markdown-pages/docs"))
    ->Mdx.filterMdxPages("docs/react")
    ->Mdx.groupBySection
    ->Dict.mapValues(values =>
      values->Mdx.sortSection->SidebarHelpers.convertToNavItems("/docs/react")
    )

  SidebarHelpers.getAllGroups(
    groups,
    ["Overview", "Main Concepts", "Hooks & State Management", "Guides"],
  )
}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)
  let filePath = MdxFile.resolveFilePath(
    (pathname :> string),
    ~dir="markdown-pages/docs/react",
    ~alias="docs/react",
  )

  let raw = await Node.Fs.readFile(filePath, "utf-8")
  let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)

  let description = FrontmatterUtils.getField(frontmatter, "description")
  let title = FrontmatterUtils.getField(frontmatter, "title")

  let categories = await reactTableOfContents()

  let compiledMdx = await MdxFile.compileMdx(raw, ~filePath, ~remarkPlugins=Mdx.plugins)

  let entries = TocUtils.buildEntries(raw)

  {
    compiledMdx,
    categories,
    entries,
    title: `${title} | ReScript React`,
    description,
    filePath,
  }
}

let default = () => {
  let {compiledMdx, categories, entries, title, description, filePath} = ReactRouter.useLoaderData()

  let breadcrumbs = list{
    {Url.name: "Docs", href: "/docs/react/introduction"},
    {
      Url.name: "rescript-react",
      href: "/docs/react/introduction",
    },
  }

  let editHref = `https://github.com/rescript-lang/rescript-lang.org/blob/master/${filePath}`

  let activeToc = {TableOfContents.title, entries}

  <>
    <Meta title description />
    <NavbarTertiary sidebar={<DocsSidebar categories activeToc />}>
      <SidebarLayout.BreadCrumbs crumbs=breadcrumbs />
      <a
        href=editHref className="inline text-14 hover:underline text-fire" rel="noopener noreferrer"
      >
        {React.string("Edit")}
      </a>
    </NavbarTertiary>
    <DocsLayout categories activeToc>
      <div className="markdown-body">
        <MdxContent compiledMdx />
      </div>
    </DocsLayout>
  </>
}
