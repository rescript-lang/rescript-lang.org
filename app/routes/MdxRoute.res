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

// The loadAllMdx function logs out all of the file contents as it reads them, which is noisy and not useful.
// We can suppress that logging with this helper function.
let allMdx = await Shims.runWithoutLogging(() => loadAllMdx())

let sortSection = mdxPages =>
  Array.toSorted(mdxPages, (a: Mdx.attributes, b: Mdx.attributes) =>
    switch (a.order, b.order) {
    | (Some(a), Some(b)) => a > b ? 1.0 : -1.0
    | _ => -1.0
    }
  )

let groupBySection = mdxPages =>
  Array.reduce(mdxPages, (Dict.make() :> Dict.t<array<Mdx.attributes>>), (acc, item) => {
    let section = item.section->Option.flatMap(Dict.get(acc, _))
    switch section {
    // If the section already exists, add this item to it
    | Some(section) => section->Array.push(item)
    // otherwise create a new section with this item
    | None => item.section->Option.forEach(section => acc->Dict.set(section, [item]))
    }
    acc
  })

let convertToNavItems = items =>
  Array.map(items, (item): SidebarLayout.Sidebar.NavItem.t => {
    {
      name: item.title,
      href: item.canonical, // TODO: RR7 - canonical works for now, but we should make this more robust so that it's not required
    }
  })

let filterMdxPages = (mdxPages, path) =>
  Array.filter(mdxPages, mdx => (mdx.path :> string)->String.includes(path))

// These are the pages for the language manual, sorted by their "order" field in the frontmatter
let manualTableOfContents = () => {
  let groups =
    allMdx
    ->filterMdxPages("docs/manual")
    ->groupBySection
    ->Dict.mapValues(values => values->sortSection->convertToNavItems)

  // Console.log(groups)

  // these are the categories that appear in the sidebar
  let categories: array<SidebarLayout.Sidebar.Category.t> = [
    {name: "Overview", items: groups->Dict.getUnsafe("Overview")},
    {name: "Guides", items: groups->Dict.getUnsafe("Guides")},
    {name: "Language Features", items: groups->Dict.getUnsafe("Language Features")},
    {name: "JavaScript Interop", items: groups->Dict.getUnsafe("JavaScript Interop")},
    {name: "Build System", items: groups->Dict.getUnsafe("Build System")},
    {name: "Advanced Features", items: groups->Dict.getUnsafe("Advanced Features")},
  ]
  categories
}

let apiTableOfContents = () => {
  let groups =
    allMdx
    ->filterMdxPages("docs/manual/api")
    ->groupBySection
    ->Dict.mapValues(values => values->sortSection->convertToNavItems)

  // Console.log(groups)

  // these are the categories that appear in the sidebar
  let categories: array<SidebarLayout.Sidebar.Category.t> = [
    {name: "Overview", items: groups->Dict.get("Overview")->Option.getOr([])},
    {
      name: "Additional Libraries",
      items: groups->Dict.get("Additional Libraries")->Option.getOr([]),
    },
  ]
  categories
}

let loader: Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)
  Console.log(pathname)
  let mdx = await loadMdx(request)

  // TODO: actually render the blog pages
  if pathname->String.includes("blog") {
    let res: loaderData = {
      __raw: mdx.__raw,
      attributes: mdx.attributes,
      entries: [],
      categories: [],
    }

    res
  } else {
    let categories = {
      if pathname->String.includes("docs/manual/api") {
        Console.log(apiTableOfContents())
        []
      } else if pathname->String.includes("docs/manual") {
        manualTableOfContents()
      } else {
        []
      }
    }

    // TODO: this can be optionally called if we need markdown
    // TODO: extract this out into a separate function
    let fileContents = await allMdx
    ->Array.filter(mdx => (mdx.path :> string)->String.includes(pathname))
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
      ->Array.slice(~start=2) // skip first two entries which are the document entry and the H1 title for the page, we just want the h2 sections

    let res: loaderData = {
      __raw: mdx.__raw,
      attributes: mdx.attributes,
      entries,
      categories,
    }

    res
  }
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
