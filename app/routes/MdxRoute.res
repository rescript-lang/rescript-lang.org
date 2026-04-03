open Mdx

type loaderData = {
  ...Mdx.t,
  categories: array<SidebarLayout.Sidebar.Category.t>,
  entries: array<TableOfContents.entry>,
  breadcrumbs?: list<Url.breadcrumb>,
  title: string,
  filePath: option<string>,
}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let {pathname} = WebAPI.URL.make(~url=request.url)

  let mdx = await loadMdx(request, ~options={remarkPlugins: Mdx.plugins})

  let categories = []

  let filePath = ref(None)

  let fileContents = await (await allMdx())
  ->Array.filter(mdx => {
    switch (mdx.slug, mdx.canonical) {
    // Having a canonical path is the best way to ensure we get the right file
    | (_, Nullable.Value(canonical)) => pathname == (canonical :> string)
    // if we don't have a canonical path, see if we can find the slug in the pathname
    | (Some(slug), _) => pathname->String.includes(slug)
    // otherwise we can't match it and the build should fail
    | _ => false
    }
  })
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
  ->Option.getOrThrow(~message="Could not find MDX file for path " ++ (pathname :> string))

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
      : None

  let metaTitleCategory = {
    let path = (pathname :> string)
    if path->String.includes("docs/manual") {
      "ReScript Language Manual"
    } else {
      "ReScript"
    }
  }

  let title = mdx.attributes.title

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

let default = () => {
  let {pathname} = ReactRouter.useLocation()
  let component = useMdxComponent()
  let attributes = useMdxAttributes()

  let loaderData: loaderData = ReactRouter.useLoaderData()

  let {entries, categories, title} = loaderData

  <>
    {if (
      (pathname :> string)->String.includes("docs/manual") ||
        (pathname :> string)->String.includes("docs/react")
    ) {
      <>
        <Meta title=title description={attributes.description->Nullable.getOr("")} />
        <NavbarSecondary />
        {
          let breadcrumbs = loaderData.breadcrumbs->Option.map(crumbs =>
            List.mapWithIndex(crumbs, (item, index) => {
              if index === 0 {
                if (pathname :> string)->String.includes("docs/manual") {
                  {...item, href: "/docs/manual/introduction"}
                } else {
                  item
                }
              } else {
                item
              }
            })
          )
          let editHref = `https://github.com/rescript-lang/rescript-lang.org/blob/master${loaderData.filePath->Option.getOrThrow}`

          let sidebarContent =
            <aside className="px-4 w-full block">
              <div className="flex justify-between items-baseline">
                <div className="flex flex-col text-fire font-medium">
                  <VersionSelect />
                </div>
                <button
                  className="flex items-center"
                  onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}
                >
                  <Icon.Close />
                </button>
              </div>
              <div className="mb-56">
                {categories
                ->Array.map(category => {
                  let isItemActive = (navItem: SidebarLayout.Sidebar.NavItem.t) =>
                    navItem.href === (pathname :> string)
                  let getActiveToc = (navItem: SidebarLayout.Sidebar.NavItem.t) =>
                    if navItem.href === (pathname :> string) {
                      Some({TableOfContents.title, entries})
                    } else {
                      None
                    }
                  <div key=category.name>
                    <SidebarLayout.Sidebar.Category
                      isItemActive
                      getActiveToc
                      category
                      onClick={_ => NavbarUtils.closeMobileTertiaryDrawer()}
                    />
                  </div>
                })
                ->React.array}
              </div>
            </aside>

          <>
            <NavbarTertiary sidebar=sidebarContent>
              {breadcrumbs->Option.mapOr(React.null, crumbs =>
                <SidebarLayout.BreadCrumbs crumbs />
              )}
              <a
                href=editHref
                className="inline text-14 hover:underline text-fire"
                rel="noopener noreferrer"
              >
                {React.string("Edit")}
              </a>
            </NavbarTertiary>
            <DocsLayout categories activeToc={title, entries}>
              <div className="markdown-body"> {component()} </div>
            </DocsLayout>
          </>
        }
      </>
    } else {
      React.null
    }}
  </>
}
