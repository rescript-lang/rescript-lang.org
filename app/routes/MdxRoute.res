open ReactRouter
open Mdx

type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
}

/**
 This configures the MDX component to use our custom markdown components
 */
let components = {
  // Replacing HTML defaults
  "a": Markdown.A.make,
  "blockquote": Markdown.Blockquote.make,
  "code": Markdown.Code.make,
  "h1": Markdown.H1.make,
  "h2": Markdown.H2.make,
  "h3": Markdown.H3.make,
  "h4": Markdown.H4.make,
  "h5": Markdown.H5.make,
  "hr": Markdown.Hr.make,
  "intro": Markdown.Intro.make,
  "li": Markdown.Li.make,
  "ol": Markdown.Ol.make,
  "p": Markdown.P.make,
  "pre": Markdown.Pre.make,
  "strong": Markdown.Strong.make,
  "table": Markdown.Table.make,
  "th": Markdown.Th.make,
  "thead": Markdown.Thead.make,
  "ul": Markdown.Ul.make,
  // These are custom components we provide
  "Cite": Markdown.Cite.make,
  "CodeTab": Markdown.CodeTab.make,
  "Image": Markdown.Image.make,
  "Info": Markdown.Info.make,
  "Intro": Markdown.Intro.make,
  "UrlBox": Markdown.UrlBox.make,
  "Video": Markdown.Video.make,
  "Warn": Markdown.Warn.make,
}

// the loadAllMdx function logs out all of the file contents as it reads them, which is noisy and not useful.
// We can suppress that logging with this helper function.
let allMdx = await Shims.runWithoutLogging(() => loadAllMdx())

let loader: Loader.t<loaderData> = async ({request}) => {
  let mdx = await loadMdx(request)

  let fileContents = await allMdx
  ->Array.filter(mdx => (mdx.path :> string)->String.includes("docs/manual/introduction"))
  ->Array.get(0)
  ->Option.map(mdx => mdx.path)
  ->Option.map(path => Node.Fs.readFile((path :> string), "utf-8"))
  ->Option.getOrThrow

  let markdownTree = Mdast.fromMarkdown(fileContents)
  let tocResult = Mdast.toc(markdownTree, {maxDepth: 2})

  let headers = Js.Dict.empty()

  Mdast.reduceHeaders(tocResult.map, headers)

  let entries =
    headers
    ->Dict.toArray
    ->Array.map(((header, url)): TableOfContents.entry => {
      header,
      href: (url :> string),
    })
    ->Array.slice(~start=2) // skip first two entries which are "Introduction" and "Getting Started"

  let res: loaderData = {
    __raw: mdx.__raw,
    attributes: mdx.attributes,
    entries,
    categories: [
      {
        name: "overview",
        items: [{name: "Introduction", href: #"/docs/manual/introduction"}],
      },
    ],
  }
  res
}

let default = () => {
  let {pathname} = useLocation()
  let component = useMdxComponent(~components)
  let attributes = useMdxAttributes()

  let {categories, entries} = useLoaderData()

  let metaTitleCategory =
    (pathname :> string)->String.includes("docs/manual")
      ? "ReScript Language Manual"
      : "Some other page"

  if (
    (pathname :> string)->String.includes("docs/manual") ||
      (pathname :> string)->String.includes("docs/react")
  ) {
    <DocsLayout metaTitleCategory categories activeToc={title: "Introduction", entries}>
      <div className="markdown-body"> {component()} </div>
    </DocsLayout>
  } else {
    // TODO Handle blog pages
    React.null
  }

  // </ManualDocsLayout.V1200Layout>
}
