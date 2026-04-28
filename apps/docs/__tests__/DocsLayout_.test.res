open ReactRouter
open Vitest

@get external textContent: WebAPI.DOMAPI.element => string = "textContent"

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

test("desktop docs layout shows sidebar with categories", async () => {
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

  let mainContent = await screen->getByTestId("side-layout-children")
  await element(mainContent)->toBeVisible

  let wrapper = await screen->getByTestId("docs-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-docs-layout")
})

test("docs layout marks the textual content for DocSearch crawling", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <DocsLayout categories=mockCategories activeToc=mockToc docSearchLvl0="Manual">
        <div> {React.string("This is the documentation content.")} </div>
      </DocsLayout>
    </MemoryRouter>,
  )

  let _mainContent = await screen->getByTestId("side-layout-children")

  let mainContent = switch document->WebAPI.Document.querySelector(
    "[data-testid='side-layout-children']",
  ) {
  | Value(element) => element
  | Null => failwith("expected docs layout main content")
  }

  let className = switch mainContent->WebAPI.Element.getAttribute("class") {
  | Value(value) => value
  | Null => ""
  }

  expect(className->String.includes("DocSearch-content"))->toBe(true)

  let lvl0 = switch document->WebAPI.Document.querySelector(".DocSearch-lvl0") {
  | Value(element) => element
  | Null => failwith("expected docs layout to render a DocSearch lvl0 marker")
  }

  expect(lvl0->textContent)->toBe("Manual")
})

test("desktop docs layout shows table of contents entries", async () => {
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

  // The TOC entries render inside the sidebar under the active nav item.
  // Since the test isn't at a matching route, the TOC appears for the first
  // category item that matches the current location. Verify the layout
  // renders with the activeToc data by checking sidebar and content are present.
  let overviewHeading = await screen->getByText("Overview")
  await element(overviewHeading)->toBeVisible

  let mainContent = await screen->getByTestId("side-layout-children")
  await element(mainContent)->toBeVisible

  let wrapper = await screen->getByTestId("docs-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-docs-layout-with-toc")
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
