type loaderData = {
  compiledMdx: CompiledMdx.t,
  blogPost: BlogApi.post,
  title: string,
}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)
  let filePath = MdxFile.resolveFilePath(
    (pathname :> string),
    ~dir="markdown-pages/blog",
    ~alias="blog",
  )

  let raw = await Node.Fs.readFile(filePath, "utf-8")
  let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)

  let frontmatter = switch BlogFrontmatter.decode(frontmatter) {
  | Ok(fm) => fm
  | Error(msg) => JsError.throwWithMessage(msg)
  }

  let compiledMdx = await MdxFile.compileMdx(raw, ~filePath, ~remarkPlugins=Mdx.plugins)

  let archived = filePath->String.includes("/archived/")

  let slug =
    filePath
    ->Node.Path.basename
    ->String.replace(".mdx", "")
    ->String.replaceRegExp(/^\d\d\d\d-\d\d-\d\d-/, "")

  let path = archived ? "archived/" ++ slug : slug

  let blogPost: BlogApi.post = {
    path,
    archived,
    frontmatter,
  }

  {
    compiledMdx,
    blogPost,
    title: `${frontmatter.title} | ReScript Blog`,
  }
}

let default = () => {
  let {compiledMdx, blogPost: {frontmatter, archived, path}} = ReactRouter.useLoaderData()

  <BlogArticle frontmatter isArchived=archived path>
    <MdxContent compiledMdx />
  </BlogArticle>
}
