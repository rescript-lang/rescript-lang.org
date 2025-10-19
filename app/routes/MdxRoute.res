open ReactRouter
open Mdx

type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  blogPost?: BlogApi.post,
  resources?: array<CommunityContent.link>,
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
  "td": Markdown.Td.make,
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
  "CommunityContent": CommunityContent.make,
}

let convertToNavItems = (items, rootPath) =>
  Array.map(items, (item): SidebarLayout.Sidebar.NavItem.t => {
    let href = switch item.slug {
    | Some(slug) => `${rootPath}/${slug}`
    | None => rootPath
    }
    {
      name: item.title,
      href,
    }
  })

let getGroup = (groups, groupName): SidebarLayout.Sidebar.Category.t => {
  {
    name: groupName,
    items: groups
    ->Dict.get(groupName)
    ->Option.getOr([]),
  }
}

let getAllGroups = (groups, groupNames): array<SidebarLayout.Sidebar.Category.t> =>
  groupNames->Array.map(item => getGroup(groups, item))

let blogPosts = async () => {
  (await allMdx())->filterMdxPages("blog")
}

// These are the pages for the language manual, sorted by their "order" field in the frontmatter
let manualTableOfContents = async () => {
  let groups =
    (await allMdx())
    ->filterMdxPages("docs/manual")
    ->groupBySection
    ->Dict.mapValues(values => values->sortSection->convertToNavItems("/docs/manual"))

  // these are the categories that appear in the sidebar
  let categories: array<SidebarLayout.Sidebar.Category.t> = getAllGroups(
    groups,
    [
      "Overview",
      "Guides",
      "Language Features",
      "JavaScript Interop",
      "Build System",
      "Advanced Features",
    ],
  )

  categories
}

let reactTableOfContents = async () => {
  let groups =
    (await allMdx())
    ->filterMdxPages("docs/react")
    ->groupBySection
    ->Dict.mapValues(values => values->sortSection->convertToNavItems("/docs/react"))

  // these are the categories that appear in the sidebar
  let categories: array<SidebarLayout.Sidebar.Category.t> = getAllGroups(
    groups,
    ["Overview", "Main Concepts", "Hooks & State Management", "Guides", "Extra"],
  )

  categories
}

let communityTableOfContents = async () => {
  let groups =
    (await allMdx())
    ->filterMdxPages("community")
    ->groupBySection
    ->Dict.mapValues(values => values->sortSection->convertToNavItems("/community"))

  // these are the categories that appear in the sidebar
  let categories: array<SidebarLayout.Sidebar.Category.t> = getAllGroups(groups, ["Resources"])

  categories
}

@module("../../data/resources.json")
external resources: array<CommunityContent.link> = "default"

let loader: Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)

  let mdx = await loadMdx(request, ~options={remarkPlugins: [Mdx.gfm]})

  // TODO: actually render the blog pages
  if pathname->String.includes("blog") {
    let posts = blogPosts()

    let res: loaderData = {
      __raw: mdx.__raw,
      attributes: mdx.attributes,
      entries: [],
      categories: [],
      blogPost: mdx.attributes->BlogLoader.transform,
    }

    res
  } else {
    let categories = {
      if pathname == "/docs/manual/api" {
        []
      } else if pathname->String.includes("docs/manual") {
        await manualTableOfContents()
      } else if pathname->String.includes("docs/react") {
        await reactTableOfContents()
      } else if pathname->String.includes("community") {
        await communityTableOfContents()
      } else {
        []
      }
    }

    // TODO: this can be optionally called if we need markdown
    // TODO: extract this out into a separate function
    let fileContents = await (await allMdx())
    ->Array.filter(mdx => (mdx.path :> string)->String.includes(pathname))
    ->Array.get(0)
    ->Option.map(mdx => mdx.path)
    ->Option.map(path => Node.Fs.readFile((path :> string), "utf-8"))
    ->Option.getOrThrow

    let markdownTree = Mdast.fromMarkdown(fileContents)
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
      ->Array.slice(~start=2) // skip first two entries which are the document entry and the H1 title for the page, we just want the h2 sections

    let res: loaderData = {
      __raw: mdx.__raw,
      attributes: mdx.attributes,
      entries,
      categories,
      resources,
    }

    res
  }
}

let default = () => {
  let {pathname} = useLocation()
  let component = useMdxComponent(~components)
  let attributes = useMdxAttributes()

  let loaderData: loaderData = useLoaderData()

  let {entries, categories} = loaderData

  // TODO: get actual meta categories working
  let metaTitleCategory =
    (pathname :> string)->String.includes("docs/manual")
      ? "ReScript Language Manual"
      : "Some other page"
  <>
    <title> {React.string(attributes.metaTitle->Nullable.getOr(attributes.title))} </title>
    <meta name="description" content={attributes.description->Nullable.getOr("")} />
    {if (pathname :> string) == "/docs/manual/api" {
      <ApiOverviewLayout.Docs> {component()} </ApiOverviewLayout.Docs>
    } else if (
      (pathname :> string)->String.includes("docs/manual") ||
        (pathname :> string)->String.includes("docs/react")
    ) {
      <DocsLayout metaTitleCategory categories activeToc={title: "Introduction", entries}>
        <div className="markdown-body"> {component()} </div>
      </DocsLayout>
    } else if (pathname :> string)->String.includes("community") {
      let resources = loaderData.resources->Option.getOr([])
      <div>
        <SidebarLayout.Sidebar
          categories={categories} isOpen={true} route={pathname} toggle={() => ()}
        />
        <div className="markdown-body"> {component()} </div>
      </div>
    } else {
      switch loaderData.blogPost {
      | Some({frontmatter, archived, path}) =>
        <BlogArticle frontmatter isArchived=archived path> {component()} </BlogArticle>
      | None => React.null // TODO: RR7 show an error
      }
    }}
  </>

  // </ManualDocsLayout.V1200Layout>
}
