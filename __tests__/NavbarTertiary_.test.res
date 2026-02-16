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

test("desktop shows breadcrumbs and edit link", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <BrowserRouter>
      <NavbarTertiary sidebar=sidebarContent>
        breadcrumbs
        editLink
      </NavbarTertiary>
    </BrowserRouter>,
  )

  let navbar = await screen->getByTestId("navbar-tertiary")

  await element(navbar)->toBeVisible

  let crumbs = await screen->getByTestId("breadcrumbs")
  await element(crumbs)->toBeVisible

  let edit = await screen->getByTestId("edit-link")
  await element(edit)->toBeVisible

  await element(navbar)->toMatchScreenshot("desktop-navbar-tertiary")
})

test("mobile shows breadcrumbs and drawer button", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <NavbarTertiary sidebar=sidebarContent>
        breadcrumbs
        editLink
      </NavbarTertiary>
    </BrowserRouter>,
  )

  let navbar = await screen->getByTestId("navbar-tertiary")
  await element(navbar)->toBeVisible

  let crumbs = await screen->getByTestId("breadcrumbs")
  await element(crumbs)->toBeVisible

  let edit = await screen->getByTestId("edit-link")
  await element(edit)->toBeVisible

  await element(navbar)->toMatchScreenshot("mobile-navbar-tertiary")
})

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

  // Sidebar dialog should not be visible initially
  let sidebar = await screen->getByTestId("sidebar-categories")
  await element(sidebar)->notToBeVisible

  // Click the drawer toggle button
  let drawerButton = await screen->getByRole(#button)
  await drawerButton->click

  // Sidebar content should now be visible
  let sidebarAfter = await screen->getByTestId("sidebar-categories")
  await element(sidebarAfter)->toBeVisible

  let versionSelect = await screen->getByTestId("sidebar-version-select")
  await element(versionSelect)->toBeVisible
})
