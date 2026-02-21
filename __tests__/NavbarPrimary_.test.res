open ReactRouter
open Vitest

test("desktop has everything visible", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <BrowserRouter>
      <NavbarPrimary />
    </BrowserRouter>,
  )

  let leftContent = await screen->getByTestId("navbar-primary-left-content")

  await element(await leftContent->getByText("Docs"))->toBeVisible
  await element(await leftContent->getByText("Playground"))->toBeVisible
  await element(await leftContent->getByText("Blog"))->toBeVisible
  await element(await leftContent->getByText("Community"))->toBeVisible

  let rightContent = await screen->getByTestId("navbar-primary-right-content")

  await element(await rightContent->getByLabelText("GitHub"))->toBeVisible
  await element(await rightContent->getByLabelText("X (formerly Twitter)"))->toBeVisible
  await element(await rightContent->getByLabelText("Bluesky"))->toBeVisible
  await element(await rightContent->getByLabelText("Forum"))->toBeVisible

  let navbar = await screen->getByTestId("navbar-primary")

  await element(navbar)->toMatchScreenshot("desktop-navbar-primary")
})

test("tablet has everything visible", async () => {
  await viewport(900, 500)

  let screen = await render(
    <BrowserRouter>
      <NavbarPrimary />
    </BrowserRouter>,
  )

  let leftContent = await screen->getByTestId("navbar-primary-left-content")

  await element(await leftContent->getByText("Docs"))->toBeVisible
  await element(await leftContent->getByText("Playground"))->toBeVisible
  await element(await leftContent->getByText("Blog"))->toBeVisible
  await element(await leftContent->getByText("Community"))->toBeVisible

  let rightContent = await screen->getByTestId("navbar-primary-right-content")

  await element(await rightContent->getByLabelText("GitHub"))->toBeVisible
  await element(await rightContent->getByLabelText("X (formerly Twitter)"))->toBeVisible
  await element(await rightContent->getByLabelText("Bluesky"))->toBeVisible
  await element(await rightContent->getByLabelText("Forum"))->toBeVisible

  let navbar = await screen->getByTestId("navbar-primary")

  await element(navbar)->toMatchScreenshot("tablet-navbar-primary")
})

test("phone has some things hidden and a mobile nav that can be toggled", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <NavbarPrimary />
    </BrowserRouter>,
  )

  let leftContent = await screen->getByTestId("navbar-primary-left-content")

  await element(await leftContent->getByText("Docs"))->toBeVisible
  await element(await leftContent->getByText("Playground"))->notToBeVisible
  await element(await leftContent->getByText("Blog"))->notToBeVisible
  await element(await leftContent->getByText("Community"))->notToBeVisible

  let rightContent = await screen->getByTestId("navbar-primary-right-content")

  await element(await rightContent->getByLabelText("GitHub"))->notToBeVisible
  await element(await rightContent->getByLabelText("X (formerly Twitter)"))->notToBeVisible
  await element(await rightContent->getByLabelText("Bluesky"))->notToBeVisible
  await element(await rightContent->getByLabelText("Forum"))->notToBeVisible

  let mobileNav = await screen->getByTestId("mobile-nav")
  await element(mobileNav)->notToBeVisible

  let button = await screen->getByTestId("toggle-mobile-overlay")

  await element(button)->toBeVisible

  await button->click

  let mobileNavAfterOpen = await screen->getByTestId("mobile-nav")

  await element(mobileNavAfterOpen)->toBeVisible

  let navbar = await screen->getByTestId("navbar-primary")

  await element(navbar)->toMatchScreenshot("mobile-navbar-primary")

  await element(mobileNavAfterOpen)->toMatchScreenshot("mobile-overlay-navbar-primary")
})
