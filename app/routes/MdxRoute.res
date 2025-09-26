open ReactRouter
open Mdx

module Sidebar = SidebarLayout.Sidebar

module NavItem = Sidebar.NavItem
module Category = Sidebar.Category

type loaderData = {...Mdx.t}

let loader: Loader.t<loaderData> = async ({request}) => {
  let mdx = await loadMdx(request)
  let res: loaderData = {__raw: mdx.__raw, attributes: mdx.attributes}
  res
}

let default = () => {
  let component = useMdxComponent()
  let attributes = useMdxAttributes()
  let _ = Toc.useToc(~category="manual")

  // TODO directly use layout and pass props

  // Console.log(attributes)
  // <ManualDocsLayout.V1200Layout
  //   metaTitleCategory="ReScript Language Manual"
  //   version="latest"
  //   availableVersions=Constants.allManualVersions
  //   nextVersion=?Constants.nextVersion>
  //   // {React.string(attributes.title)} </h1>
  <div className="markdown-body">
    <DocsLayout metaTitleCategory="Foo" categories=[]> {component()} </DocsLayout>
  </div>
  // </ManualDocsLayout.V1200Layout>
}
