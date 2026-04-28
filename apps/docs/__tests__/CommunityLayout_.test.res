open ReactRouter
open Vitest

let mockCategories: array<SidebarNav.Category.t> = [
  {
    name: "Resources",
    items: [
      {name: "Overview", href: "/community/overview"},
      {name: "Code of Conduct", href: "/community/code-of-conduct"},
      {name: "Roadmap", href: "/community/roadmap"},
    ],
  },
]

let mockEntries: array<TableOfContents.entry> = [
  {header: "Official Channels", href: "#official-channels"},
  {header: "Community Projects", href: "#community-projects"},
]

test("desktop community layout shows sidebar and content", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="community-layout-wrapper">
        <CommunityLayout categories=mockCategories entries=mockEntries>
          <div> {React.string("Community content goes here.")} </div>
        </CommunityLayout>
      </div>
    </BrowserRouter>,
  )

  let resources = await screen->getByText("Resources")
  await element(resources)->toBeVisible

  let overview = await screen->getByText("Overview")
  await element(overview)->toBeVisible

  let content = await screen->getByTestId("side-layout-children")
  await element(content)->toBeVisible

  let wrapper = await screen->getByTestId("community-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-community-layout")
})

test("mobile community layout hides sidebar", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="community-layout-wrapper">
        <CommunityLayout categories=mockCategories entries=mockEntries>
          <div> {React.string("Community content goes here.")} </div>
        </CommunityLayout>
      </div>
    </BrowserRouter>,
  )

  let resources = await screen->getByText("Resources")
  await element(resources)->notToBeVisible

  let overview = await screen->getByText("Overview")
  await element(overview)->notToBeVisible

  let wrapper = await screen->getByTestId("community-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-community-layout")
})

let mockMultipleCategories: array<SidebarNav.Category.t> = [
  {
    name: "Resources",
    items: [
      {name: "Overview", href: "/community/overview"},
      {name: "Code of Conduct", href: "/community/code-of-conduct"},
    ],
  },
  {
    name: "Get Involved",
    items: [
      {name: "Contributing", href: "/community/contributing"},
      {name: "Events", href: "/community/events"},
    ],
  },
]

test("desktop community layout with multiple categories", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="community-layout-wrapper">
        <CommunityLayout categories=mockMultipleCategories entries=mockEntries>
          <div> {React.string("Community content with multiple categories.")} </div>
        </CommunityLayout>
      </div>
    </BrowserRouter>,
  )

  let resources = await screen->getByText("Resources")
  await element(resources)->toBeVisible

  let getInvolved = await screen->getByText("Get Involved")
  await element(getInvolved)->toBeVisible

  let contributing = await screen->getByText("Contributing")
  await element(contributing)->toBeVisible

  let wrapper = await screen->getByTestId("community-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-community-layout-multi-categories")
})

test("tablet community layout", async () => {
  await viewport(900, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="community-layout-wrapper">
        <CommunityLayout categories=mockCategories entries=mockEntries>
          <div> {React.string("Community content goes here.")} </div>
        </CommunityLayout>
      </div>
    </BrowserRouter>,
  )

  let resources = await screen->getByText("Resources")
  await element(resources)->toBeVisible

  let wrapper = await screen->getByTestId("community-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("tablet-community-layout")
})
