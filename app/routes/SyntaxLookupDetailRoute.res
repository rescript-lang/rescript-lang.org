type loaderData = {
  compiledMdx: CompiledMdx.t,
  mdxSources: array<SyntaxLookup.item>,
  activeSyntaxItem: option<SyntaxLookup.item>,
  title: string,
  description: string,
}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)
  let filePath = MdxFile.resolveFilePath(
    (pathname :> string),
    ~dir="markdown-pages/syntax-lookup",
    ~alias="syntax-lookup",
  )

  let raw = await Node.Fs.readFile(filePath, "utf-8")
  let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)

  let id = switch frontmatter {
  | Object(dict) =>
    switch dict->Dict.get("id") {
    | Some(String(s)) => s
    | _ => ""
    }
  | _ => ""
  }

  let name = switch frontmatter {
  | Object(dict) =>
    switch dict->Dict.get("name") {
    | Some(String(s)) => s
    | _ => ""
    }
  | _ => ""
  }

  let compiledMdx = await MdxFile.compileMdx(raw, ~filePath, ~remarkPlugins=Mdx.plugins)

  let mdxSources =
    (await MdxFile.loadAllAttributes(~dir="markdown-pages/syntax-lookup"))->Array.map(
      SyntaxLookupRoute.convert,
    )

  let activeSyntaxItem = mdxSources->Array.find(item => item.id == id)

  {
    compiledMdx,
    mdxSources,
    activeSyntaxItem,
    title: name,
    description: "",
  }
}

let default = () => {
  let {compiledMdx, mdxSources, activeSyntaxItem} = ReactRouter.useLoaderData()

  <>
    <Meta
      title={activeSyntaxItem
      ->Option.map(item => item.name)
      ->Option.getOr("Syntax Lookup | ReScript API")}
      description=""
    />
    <NavbarSecondary />
    <SyntaxLookup mdxSources activeItem=?activeSyntaxItem>
      <MdxContent compiledMdx />
    </SyntaxLookup>
  </>
}
