@react.component
let make = (~children, ~categories, ~entries) => {
  let {pathname} = ReactRouter.useLocation()

  Console.log((pathname :> string)->String.split("/"))

  let activePage =
    (pathname :> string)
    ->String.split("/")
    ->Array.filter(str => str !== "")
    ->Array.at(1)
    ->Option.getOr("Community")
    ->String.replaceAll("-", " ")
    ->Util.String.capitalizeSentence

  let breadcrumbs = list{{Url.name: "Community", href: "/community"}}

  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)
  <>
    <Meta title={`${activePage} | ReScript Community`} />
    <SidebarLayout
      sidebar={<SidebarLayout.Sidebar
        categories
        isOpen={isSidebarOpen}
        route=pathname
        toggle={() => setSidebarOpen(prev => !prev)}
        activeToc={title: "Overview", entries}
      />}
      sidebarState=(isSidebarOpen, setSidebarOpen)
      theme=#Reason
      breadcrumbs
    >
      children
    </SidebarLayout>
  </>
}
