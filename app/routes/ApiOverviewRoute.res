let categories: array<SidebarLayout.Sidebar.Category.t> = [
  {
    name: "Overview",
    items: [
      {name: "Introduction", href: "/docs/manual/api"},
      {name: "Stdlib", href: "/docs/manual/api/stdlib"},
    ],
  },
  {
    name: "Additional Libraries",
    items: [
      {name: "Belt", href: "/docs/manual/api/belt"},
      {name: "Dom", href: "/docs/manual/api/dom"},
    ],
  },
]

type loaderData = {
  compiledMdx: CompiledMdx.t,
  title: string,
  description: string,
}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)
  let filePath = MdxFile.resolveFilePath(
    (pathname :> string),
    ~dir="markdown-pages/docs/manual",
    ~alias="docs/manual",
  )

  let raw = await Node.Fs.readFile(filePath, "utf-8")
  let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)

  let description = FrontmatterUtils.getField(frontmatter, "description")

  let compiledMdx = await MdxFile.compileMdx(raw, ~filePath, ~remarkPlugins=Mdx.plugins)

  {
    compiledMdx,
    title: "API | ReScript API",
    description,
  }
}

let default = () => {
  let {compiledMdx, title, description} = ReactRouter.useLoaderData()

  let breadcrumbs = list{
    {Url.name: "Docs", href: `/docs/manual/api`},
    {Url.name: "API", href: `/docs/manual/api`},
  }

  <>
    <Meta title description />
    <NavbarTertiary sidebar={<DocsSidebar categories />}>
      <SidebarLayout.BreadCrumbs crumbs=breadcrumbs />
    </NavbarTertiary>
    <DocsLayout categories theme=#Js docSearchLvl0="API">
      <div className="markdown-body">
        <MdxContent compiledMdx />
      </div>
    </DocsLayout>
  </>
}
