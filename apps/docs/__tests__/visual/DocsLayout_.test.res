open ReactRouter
open Vitest

let mockCategories: array<SidebarNav.Category.t> = [
  {
    name: "Overview",
    items: [
      {name: "Introduction", href: "/docs/manual/introduction"},
      {name: "Installation", href: "/docs/manual/installation"},
    ],
  },
  {
    name: "Language Features",
    items: [
      {name: "Primitive Types", href: "/docs/manual/primitive-types"},
      {name: "Record", href: "/docs/manual/record"},
      {name: "Object", href: "/docs/manual/object"},
    ],
  },
]

let mockToc: TableOfContents.t = {
  title: "Introduction",
  entries: [
    {header: "What is ReScript", href: "#what-is-rescript"},
    {header: "Prerequisites", href: "#prerequisites"},
    {header: "Getting Started", href: "#getting-started"},
  ],
}

test("desktop docs layout shows categories and active-page table of contents", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <div dataTestId="docs-layout-wrapper">
        <DocsLayout categories=mockCategories activeToc=mockToc>
          <div> {React.string("This is the documentation content.")} </div>
        </DocsLayout>
      </div>
    </MemoryRouter>,
  )

  let overviewHeading = await screen->getByText("Overview")
  await element(overviewHeading)->toBeVisible

  let languageFeaturesHeading = await screen->getByText("Language Features")
  await element(languageFeaturesHeading)->toBeVisible

  let introItem = await screen->getByText("Introduction")
  await element(introItem)->toBeVisible

  let sidebar = await screen->getByTestId("sidebar-content")
  for i in 0 to Array.length(mockToc.entries) - 1 {
    let {TableOfContents.header: header, href} = mockToc.entries->Array.getUnsafe(i)
    let tocLink = await sidebar->getByText(header)
    await element(tocLink)->toBeVisible
    await element(tocLink)->toHaveAttribute("href", "/docs/manual/introduction" ++ href)
  }

  let mainContent = await screen->getByTestId("side-layout-children")
  await element(mainContent)->toBeVisible

  let wrapper = await screen->getByTestId("docs-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-docs-layout")
})

test("mobile docs layout hides sidebar by default", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <div dataTestId="docs-layout-wrapper">
        <DocsLayout categories=mockCategories activeToc=mockToc>
          <div> {React.string("This is the documentation content.")} </div>
        </DocsLayout>
      </div>
    </MemoryRouter>,
  )

  let introItem = await screen->getByText("Introduction")
  await element(introItem)->notToBeVisible

  let mainContent = await screen->getByTestId("side-layout-children")
  await element(mainContent)->toBeVisible

  let wrapper = await screen->getByTestId("docs-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-docs-layout")
})

test("desktop docs layout highlights active nav item", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/installation"]>
      <div dataTestId="docs-layout-wrapper">
        <DocsLayout categories=mockCategories activeToc=mockToc>
          <div> {React.string("This is the documentation content.")} </div>
        </DocsLayout>
      </div>
    </MemoryRouter>,
  )

  let sidebar = await screen->getByTestId("sidebar-content")

  let installItem = await sidebar->getByText("Installation")
  await element(installItem)->toBeVisible

  let introItem = await sidebar->getByText("Introduction")
  await element(introItem)->toBeVisible

  let wrapper = await screen->getByTestId("docs-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-docs-layout-active-item")
})

test("desktop docs layout shows pagination (prev/next)", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/installation"]>
      <div dataTestId="docs-layout-wrapper">
        <DocsLayout categories=mockCategories activeToc=mockToc>
          <div> {React.string("Installation documentation content.")} </div>
        </DocsLayout>
      </div>
    </MemoryRouter>,
  )

  // When at "Installation" (second item), there should be a "Previous" link to "Introduction"
  // and a "Next" link to "Primitive Types"
  let content = await screen->getByTestId("side-layout-children")

  let prevLink = await content->getByText("Introduction")
  await element(prevLink)->toBeVisible

  let nextLink = await content->getByText("Primitive Types")
  await element(nextLink)->toBeVisible

  let wrapper = await screen->getByTestId("docs-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-docs-layout-pagination")
})
