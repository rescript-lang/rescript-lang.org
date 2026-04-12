type loaderData = {
  compiledMdx: CompiledMdx.t,
  entries: array<TableOfContents.entry>,
  title: string,
  description: string,
  filePath: string,
  categories: array<SidebarLayout.Sidebar.Category.t>,
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

  let description = switch frontmatter {
  | Object(dict) =>
    switch dict->Dict.get("description") {
    | Some(String(s)) => s
    | _ => ""
    }
  | _ => ""
  }

  let title = switch frontmatter {
  | Object(dict) =>
    switch dict->Dict.get("title") {
    | Some(String(s)) => s
    | _ => ""
    }
  | _ => ""
  }

  let compiledMdx = await MdxFile.compileMdx(raw, ~filePath, ~remarkPlugins=Mdx.plugins)

  let markdownTree = Mdast.fromMarkdown(raw)
  let tocResult = Mdast.toc(markdownTree, {maxDepth: 2})

  let headers = Dict.make()
  Mdast.reduceHeaders(tocResult.map, headers)

  let entries =
    headers
    ->Dict.toArray
    ->Array.map(((header, url)): TableOfContents.entry => {
      header,
      href: (url :> string),
    })
    ->Array.slice(~start=2)

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

  let editHref = `https://github.com/rescript-lang/rescript-lang.org/blob/master/${filePath}`

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
