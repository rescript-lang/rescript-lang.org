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

  // Build table of contents entries from markdown headings
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
    ->Array.slice(~start=2) // skip document entry and H1 title, keep h2 sections

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

  let editHref = `https://github.com/rescript-lang/rescript-lang.org/blob/master/${filePath}`

  let categories: array<SidebarLayout.Sidebar.Category.t> = []

  <>
    <Meta title description />
    <NavbarSecondary />
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
