open ReactRouter
open Vitest

let sidebarContent =
  <aside>
    <div dataTestId="sidebar-version-select"> {React.string("v12 (latest)")} </div>
    <div dataTestId="sidebar-categories">
      <div> {React.string("OVERVIEW")} </div>
      <div> {React.string("Introduction")} </div>
    </div>
  </aside>

let breadcrumbs =
  <span dataTestId="breadcrumbs"> {React.string("Docs / Language Manual / Installation")} </span>

let editLink = <a dataTestId="edit-link" href="#"> {React.string("Edit")} </a>

test("mobile drawer can be toggled open", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <NavbarTertiary sidebar=sidebarContent>
        breadcrumbs
        editLink
      </NavbarTertiary>
    </BrowserRouter>,
  )

  let sidebar = await screen->getByTestId("sidebar-categories")
  await element(sidebar)->notToBeVisible

  let drawerButton = await screen->getByRole(#button)
  await drawerButton->click

  let sidebarAfter = await screen->getByTestId("sidebar-categories")
  await element(sidebarAfter)->toBeVisible

  let versionSelect = await screen->getByTestId("sidebar-version-select")
  await element(versionSelect)->toBeVisible
})
