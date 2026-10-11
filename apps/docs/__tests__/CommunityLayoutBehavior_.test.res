open Vitest

@module("vitest/browser") @scope("userEvent")
external keyboard: string => promise<unit> = "keyboard"

@send external toHaveFocus: element => promise<unit> = "toHaveFocus"

let categories: array<SidebarNav.Category.t> = [
  {
    name: "Resources",
    items: [
      {name: "Overview", href: "/community/overview"},
      {name: "Code of Conduct", href: "/community/code-of-conduct"},
    ],
  },
]

let entries: array<TableOfContents.entry> = [
  {header: "Official Channels", href: "#official-channels"},
]

module CurrentPage = {
  @react.component
  let make = () => {
    let {pathname} = ReactRouter.useLocation()
    <div dataTestId="current-page"> {React.string((pathname :> string))} </div>
  }
}

let renderCommunity = () =>
  render(
    <ReactRouter.MemoryRouter initialEntries=["/community/overview"]>
      <CommunityLayout categories entries>
        <div>
          <CurrentPage />
          <h2 id="official-channels"> {React.string("Official channels content")} </h2>
        </div>
      </CommunityLayout>
    </ReactRouter.MemoryRouter>,
  )

test("mobile community navigation opens and closes", async () => {
  await viewport(390, 844)
  let screen = await renderCommunity()
  let trigger = await screen->getByText("Community navigation")
  let dialog = await screen->getByTestId("community-mobile-sidebar")

  await element(trigger)->toBeVisible
  await element(trigger)->toHaveAttribute("aria-expanded", "false")
  await element(dialog)->notToBeVisible
  await trigger->click

  await element(trigger)->toHaveAttribute("aria-expanded", "true")
  await element(dialog)->toBeVisible
  let resources = await dialog->getByText("Resources")
  await element(resources)->toBeVisible
  let close = await dialog->getByLabelText("Close community navigation")
  await close->click
  await element(dialog)->notToBeVisible
  await element(trigger)->toHaveAttribute("aria-expanded", "false")
})

test("Escape closes community navigation and returns focus to the opener", async () => {
  await viewport(390, 844)
  let screen = await renderCommunity()
  let trigger = await screen->getByText("Community navigation")
  let dialog = await screen->getByTestId("community-mobile-sidebar")
  await trigger->click
  await element(dialog)->toBeVisible

  await keyboard("{Escape}")
  await element(dialog)->notToBeVisible
  await element(trigger)->toHaveAttribute("aria-expanded", "false")
  await element(trigger)->toHaveFocus
})

test("community page links close the drawer, including the current page link", async () => {
  await viewport(390, 844)
  let screen = await renderCommunity()
  let trigger = await screen->getByText("Community navigation")
  let dialog = await screen->getByTestId("community-mobile-sidebar")
  await trigger->click
  let link = await dialog->getByText("Code of Conduct")
  await link->click

  let currentPage = await screen->getByTestId("current-page")
  await element(currentPage)->toHaveTextContent("/community/code-of-conduct")
  await element(dialog)->notToBeVisible

  await trigger->click
  let currentPageLink = await dialog->getByText("Code of Conduct")
  await currentPageLink->click
  await element(dialog)->notToBeVisible
})

test("community table of contents links close the mobile drawer", async () => {
  await viewport(390, 844)
  let screen = await renderCommunity()
  let trigger = await screen->getByText("Community navigation")
  let dialog = await screen->getByTestId("community-mobile-sidebar")
  await trigger->click
  let tocLink = await dialog->getByText("Official Channels")
  await tocLink->click
  await element(dialog)->notToBeVisible
})

test(
  "desktop community navigation stays visible and resizing dismisses an open drawer",
  async () => {
    await viewport(390, 844)
    let screen = await renderCommunity()
    let trigger = await screen->getByText("Community navigation")
    let dialog = await screen->getByTestId("community-mobile-sidebar")
    await trigger->click
    await element(dialog)->toBeVisible

    await viewport(900, 900)
    await element(dialog)->notToBeVisible
    await element(trigger)->notToBeVisible
    let resources = await screen->getByText("Resources")
    await element(resources)->toBeVisible

    await viewport(390, 844)
    await element(trigger)->toBeVisible
    await element(trigger)->toHaveAttribute("aria-expanded", "false")
  },
)
