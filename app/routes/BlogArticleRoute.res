type loaderData = {
  content: string,
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
  let {content, frontmatter} = await MdxFile.loadFile(filePath)

  let frontmatter = switch BlogFrontmatter.decode(frontmatter) {
  | Ok(fm) => fm
  | Error(msg) => JsError.throwWithMessage(msg)
  }

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
    content,
    blogPost,
    title: `${frontmatter.title} | ReScript Blog`,
  }
}

let default = () => {
  let {content, blogPost: {frontmatter, archived, path}} = ReactRouter.useLoaderData()

  <BlogArticle frontmatter isArchived=archived path>
    <ReactMarkdown components=MarkdownComponents.default rehypePlugins=[Rehype.Plugin(Rehype.raw)]>
      content
    </ReactMarkdown>
  </BlogArticle>
}
