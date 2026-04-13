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
  let {pathname} = ReactRouter.useLocation()
  let {compiledMdx, title, description} = ReactRouter.useLoaderData()

  let breadcrumbs = list{
    {Url.name: "Docs", href: `/docs/manual/api`},
    {Url.name: "API", href: `/docs/manual/api`},
  }

  let sidebarContent =
    <aside className="px-4 w-full block">
      <div className="flex justify-between items-baseline">
        <div className="flex flex-col text-fire font-medium">
          <VersionSelect />
        </div>
        <button
          className="flex items-center" onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}
        >
          <Icon.Close />
        </button>
      </div>
      <div className="mb-56">
        {categories
        ->Array.map(category => {
          let isItemActive = (navItem: SidebarLayout.Sidebar.NavItem.t) =>
            navItem.href === (pathname :> string)
          <div key=category.name>
            <SidebarLayout.Sidebar.Category
              isItemActive category onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}
            />
          </div>
        })
        ->React.array}
      </div>
    </aside>

  <>
    <Meta title description />
    <NavbarTertiary sidebar=sidebarContent>
      <SidebarLayout.BreadCrumbs crumbs=breadcrumbs />
    </NavbarTertiary>
    <DocsLayout categories theme=#Js>
      <div className="markdown-body">
        <MdxContent compiledMdx />
      </div>
    </DocsLayout>
  </>
}
