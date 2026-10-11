@react.component
let make = (~children, ~categories, ~entries) => {
  let {pathname} = ReactRouter.useLocation()

  let activePage =
    (pathname :> string)
    ->String.split("/")
    ->Array.filter(str => str !== "")
    ->Array.at(1)
    ->Option.getOr("Community")
    ->String.replaceAll("-", " ")
    ->Util.String.capitalizeSentence

  let activeToc: TableOfContents.t = {title: "Overview", entries}
  <>
    <Meta title={`${activePage} | ReScript Community`} />
    <CommunityMobileSidebar
      key={(pathname :> string)} route={(pathname :> string)} categories activeToc
    />
    <SidebarPageLayout
      sidebar={<SidebarNav categories isOpen=false route=pathname toggle={() => ()} activeToc />}
      docSearchLvl0="Community"
    >
      children
    </SidebarPageLayout>
  </>
}
