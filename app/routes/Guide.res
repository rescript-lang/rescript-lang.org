open Guide_Utils

// For some reason the MDX components have to be defined in the route file
%%private(
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
)

type loaderData = {...Mdx.t, sidebarItems: array<Sidebar.item>}

let loader: ReactRouter.Loader.t<loaderData> = async ({request}) => {
  let mdx = await Mdx.loadMdx(request, ~options={remarkPlugins: Mdx.plugins})
  let guidePages = await getGuidePages()
  {
    __raw: mdx.__raw,
    attributes: mdx.attributes,
    sidebarItems: guidePages->Array.map((page): Sidebar.item => {
      {
        slug: page.slug->Option.getOrThrow,
        title: page.title,
      }
    }),
  }
}

let default = () => {
  let loaderData: loaderData = ReactRouter.useLoaderData()
  // let attributes = Mdx.useMdxAttributes()
  let component = Mdx.useMdxComponent(~components)

  let scrollDirection = Hooks.useScrollDirection(~topMargin=64, ~threshold=32)

  let navbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-0"
  | Down(_) => "-translate-y-full md:translate-y-0"
  }

  let secondaryNavbarClasses = switch scrollDirection {
  | Up(_) => "translate-y-[32]"
  // TODO: this has to be full plus the 16 for the banner above
  | Down(_) => "-translate-y-[128px] md:translate-y-[32]"
  }

  <>
    <NavbarPrimary />
    <NavbarSecondary />
    <NavbarTertiary />
    <div className="flex flex-wrap max-w-7xl mx-auto min-h-lvh overflow-hidden">
      <Sidebar items={loaderData.sidebarItems} />
      <div className="basis-0 grow-999 min-w-1/2 p-8 overflow-scroll">
        <a className="text-gray-60"> {React.string("See all guides")} </a>
        {component()}
      </div>
    </div>
  </>
}
