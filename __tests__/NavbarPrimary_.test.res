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

  await element(leftContent->getByText("Docs"))->toBeVisible
  await element(leftContent->getByText("Playground"))->toBeVisible
  await element(leftContent->getByText("Blog"))->toBeVisible
  await element(leftContent->getByText("Community"))->toBeVisible

  let rightContent = await screen->getByTestId("navbar-primary-right-content")

  await element(rightContent->getByLabelText("Github"))->toBeVisible
  await element(rightContent->getByLabelText("X (formerly Twitter)"))->toBeVisible
  await element(rightContent->getByLabelText("Bluesky"))->toBeVisible
  await element(rightContent->getByLabelText("Forum"))->toBeVisible
})

test("tablet has everything visible", async () => {
  await viewport(900, 500)

  let screen = await render(
    <BrowserRouter>
      <NavbarPrimary />
    </BrowserRouter>,
  )

  let leftContent = await screen->getByTestId("navbar-primary-left-content")

  await element(leftContent->getByText("Docs"))->toBeVisible
  await element(leftContent->getByText("Playground"))->toBeVisible
  await element(leftContent->getByText("Blog"))->toBeVisible
  await element(leftContent->getByText("Community"))->toBeVisible

  let rightContent = await screen->getByTestId("navbar-primary-right-content")

  await element(rightContent->getByLabelText("Github"))->toBeVisible
  await element(rightContent->getByLabelText("X (formerly Twitter)"))->toBeVisible
  await element(rightContent->getByLabelText("Bluesky"))->toBeVisible
  await element(rightContent->getByLabelText("Forum"))->toBeVisible
})

test("phone has some things hidden and a mobile nav that can be toggled", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <NavbarPrimary />
    </BrowserRouter>,
  )

  // await element(screen->getByText("Docs"))->toBeVisible
  // await element(screen->getByText("Playground"))->notToBeVisible
  // await element(screen->getByText("Blog"))->notToBeVisible
  // await element(screen->getByText("Community"))->notToBeVisible

  await element(screen->getByTestId("mobile-nav"))->notToBeVisible

  // await element(screen->getByLabelText("Github"))->notToBeVisible
  // await element(screen->getByLabelText("X (formerly Twitter)"))->notToBeVisible
  // await element(screen->getByLabelText("Bluesky"))->notToBeVisible
  // await element(screen->getByLabelText("Forum"))->notToBeVisible

  let button = await screen->getByTestId("toggle-mobile-overlay")

  await element(button)->toBeVisible

  await button->click

  // await element(screen->getByLabelText("Github"))->toBeVisible
  // await element(screen->getByLabelText("X (formerly Twitter)"))->toBeVisible
  // await element(screen->getByLabelText("Bluesky"))->toBeVisible
  // await element(screen->getByLabelText("Forum"))->toBeVisible
})
