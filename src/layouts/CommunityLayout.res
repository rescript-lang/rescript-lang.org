@react.component
let make = (~children, ~categories, ~entries) => {
  let {pathname} = ReactRouter.useLocation()

  let breadcrumbs = list{{Url.name: "Community", href: "/community"}}

  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)

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
    metaTitle="ReScript Community"
    breadcrumbs
  >
    children
  </SidebarLayout>
}
