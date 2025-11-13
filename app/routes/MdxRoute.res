open Mdx

type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  blogPost?: BlogApi.post,
  mdxSources?: array<SyntaxLookup.item>,
  activeSyntaxItem?: SyntaxLookup.item,
  breadcrumbs?: list<Url.breadcrumb>,
  title: string,
  filePath: option<string>,
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
  "WarningTable": WarningTable.make,
  "Docson": DocsonLazy.make,
  "Suspense": React.Suspense.make,
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
    ["Overview", "Main Concepts", "Hooks & State Management", "Guides"],
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

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)

  let mdx = await loadMdx(request, ~options={remarkPlugins: [Mdx.gfm]})

  if pathname->String.includes("blog") {
    let posts = blogPosts()

    let res: loaderData = {
      __raw: mdx.__raw,
      attributes: mdx.attributes,
      entries: [],
      categories: [],
      blogPost: mdx.attributes->BlogLoader.transform,
      title: `${mdx.attributes.title} | ReScript Blog`,
      filePath: None,
    }
    res
  } else if pathname->String.includes("syntax-lookup") {
    let mdxSources =
      (await allMdx())
      ->Array.filter(page =>
        page.path
        ->Option.map(String.includes(_, "syntax-lookup"))
        ->Option.getOr(false)
      )
      ->Array.map(SyntaxLookupRoute.convert)

    let activeSyntaxItem =
      mdxSources->Array.find(item => item.id == mdx.attributes.id->Option.getOrThrow)

    let res: loaderData = {
      __raw: mdx.__raw,
      attributes: mdx.attributes,
      entries: [],
      categories: [],
      mdxSources,
      ?activeSyntaxItem,
      title: mdx.attributes.title, // TODO RR7: check if this is correct
      filePath: None,
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

    let filePath = ref(None)

    // TODO POST RR7: extract this out into a separate function
    // it can probably be cached or something
    let fileContents = await (await allMdx())
    ->Array.filter(mdx => mdx.path->Option.map(String.includes(_, pathname))->Option.getOr(false))
    ->Array.get(0)
    ->Option.flatMap(mdx => {
      filePath :=
        mdx.path->Option.map(mdxPath =>
          String.slice(mdxPath, ~start=mdxPath->String.indexOf("rescript-lang.org/") + 17)
        )
      // remove the filesystem path to get the relative path to the files in the repo
      mdx.path
    })
    ->Option.map(path => Node.Fs.readFile(path, "utf-8"))
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

    let breadcrumbs =
      pathname->String.includes("docs/manual")
        ? Some(list{
            {Url.name: "Docs", href: "/docs/"},
            {
              Url.name: "Language Manual",
              href: "/docs/manual/" ++ "introduction",
            },
          })
        : pathname->String.includes("docs/react")
        ? Some(list{
          {Url.name: "Docs", href: "/docs/"},
          {
            Url.name: "rescript-react",
            href: "/docs/react/" ++ "introduction",
          },
        })
        : None

    let metaTitleCategory = {
      let path = (pathname :> string)
      let title = if path->String.includes("docs/react") {
        "ReScript React"
      } else if path->String.includes("docs/manual/api") {
        "ReScript API"
      } else if path->String.includes("docs/manual") {
        "ReScript Language Manual"
      } else if path->String.includes("community") {
        "ReScript Community"
      } else {
        "ReScript"
      }

      title
    }

    let title = if pathname == "/docs/manual/api" {
      "API"
    } else {
      mdx.attributes.title
    }

    let res: loaderData = {
      __raw: mdx.__raw,
      attributes: mdx.attributes,
      entries,
      categories,
      ?breadcrumbs,
      title: `${title} | ${metaTitleCategory}`,
      filePath: filePath.contents,
    }
    res
  }
}

let default = () => {
  let {pathname} = ReactRouter.useLocation()
  let component = useMdxComponent(~components)
  let attributes = useMdxAttributes()

  let loaderData: loaderData = ReactRouter.useLoaderData()

  let {entries, categories, title} = loaderData

  <>
    {if (pathname :> string) == "/docs/manual/api" {
      <>
        <Meta title=title description={attributes.description->Nullable.getOr("ReScript API")} />
        <ApiOverviewLayout.Docs>
          <div className="markdown-body"> {component()} </div>
        </ApiOverviewLayout.Docs>
      </>
    } else if (
      (pathname :> string)->String.includes("docs/manual") ||
        (pathname :> string)->String.includes("docs/react")
    ) {
      <>
        <Meta title=title description={attributes.description->Nullable.getOr("")} />
        <DocsLayout
          categories
          activeToc={title: "Introduction", entries}
          breadcrumbs=?{loaderData.breadcrumbs->Option.map(crumbs =>
            List.mapWithIndex(crumbs, (item, index) => {
              if index === 0 {
                if (pathname :> string)->String.includes("docs/manual") {
                  {...item, href: "/docs/manual/introduction"}
                } else if (pathname :> string)->String.includes("docs/react") {
                  {...item, href: "/docs/react/introduction"}
                } else {
                  item
                }
              } else {
                item
              }
            })
          )}
          editHref={`https://github.com/rescript-lang/rescript-lang.org/blob/${Env.github_branch}${loaderData.filePath->Option.getOrThrow}`}
        >
          <div className="markdown-body"> {component()} </div>
        </DocsLayout>
      </>
    } else if (pathname :> string)->String.includes("community") {
      <CommunityLayout categories entries>
        <div className="markdown-body"> {component()} </div>
      </CommunityLayout>
    } else if (pathname :> string)->String.includes("blog") {
      switch loaderData.blogPost {
      | Some({frontmatter, archived, path}) =>
        <BlogArticle frontmatter isArchived=archived path> {component()} </BlogArticle>
      | None => React.null // TODO: Post RR7 show an error?
      }
    } else {
      switch loaderData.mdxSources {
      | Some(mdxSources) =>
        <>
          <Meta
            title={loaderData.activeSyntaxItem
            ->Option.map(item => item.name)
            ->Option.getOr("Syntax Lookup | ReScript API")}
            description={attributes.description->Nullable.getOr("")}
          />

          <SyntaxLookup mdxSources activeItem=?loaderData.activeSyntaxItem>
            {component()}
          </SyntaxLookup>
        </>
      | None => React.null
      }
    }}
  </>
}
