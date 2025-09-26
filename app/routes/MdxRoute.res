open ReactRouter
open Mdx

module Sidebar = SidebarLayout.Sidebar

module NavItem = Sidebar.NavItem
module Category = Sidebar.Category

type loaderData = {...Mdx.t, categories: array<SidebarLayout.Sidebar.Category.t>}

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

let loader: Loader.t<loaderData> = async ({request}) => {
  let mdx = await loadMdx(request)
  Console.log(
    (await loadAllMdx())->Array.filter(page =>
      (page.path :> string)->String.includes("docs/manual")
    ),
  )
  let res: loaderData = {
    __raw: mdx.__raw,
    attributes: mdx.attributes,
    categories: [
      {
        name: "overview",
        items: [{name: "Introduction", href: #"/docs/manual/installation"}],
      },
    ],
  }
  res
}

let default = () => {
  let {pathname} = useLocation()
  let component = useMdxComponent(~components)
  let attributes = useMdxAttributes()

  let {categories} = useLoaderData()

  let metaTitleCategory =
    (pathname :> string)->String.includes("docs/manual")
      ? "ReScript Language Manual"
      : "Some other page"
  // TODO directly use layout and pass props

  // Console.log(attributes)
  // <ManualDocsLayout.V1200Layout
  //   metaTitleCategory="ReScript Language Manual"
  //   version="latest"
  //   availableVersions=Constants.allManualVersions
  //   nextVersion=?Constants.nextVersion>
  //   // {React.string(attributes.title)} </h1>
  <div>
    <DocsLayout metaTitleCategory categories>
      <div className="markdown-body"> {component()} </div>
    </DocsLayout>
  </div>
  // </ManualDocsLayout.V1200Layout>
}
