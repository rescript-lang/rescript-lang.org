open ReactRouter
open Vitest

test("desktop has everything visible", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <BrowserRouter>
      <NavbarPrimary />
    </BrowserRouter>,
  )

  await element(screen->getByText("Docs"))->toBeVisible
  await element(screen->getByText("Playground"))->toBeVisible
  await element(screen->getByText("Blog"))->toBeVisible
  await element(screen->getByText("Community"))->toBeVisible

  await element(screen->getByLabelText("Github"))->toBeVisible
  await element(screen->getByLabelText("X (formerly Twitter)"))->toBeVisible
  await element(screen->getByLabelText("Bluesky"))->toBeVisible
  await element(screen->getByLabelText("Forum"))->toBeVisible
})

test("tablet has everything visible", async () => {
  await viewport(900, 500)

  let screen = await render(
    <BrowserRouter>
      <NavbarPrimary />
    </BrowserRouter>,
  )

  await element(screen->getByText("Docs"))->toBeVisible
  await element(screen->getByText("Playground"))->toBeVisible
  await element(screen->getByText("Blog"))->toBeVisible
  await element(screen->getByText("Community"))->toBeVisible

  await element(screen->getByLabelText("Github"))->toBeVisible
  await element(screen->getByLabelText("X (formerly Twitter)"))->toBeVisible
  await element(screen->getByLabelText("Bluesky"))->toBeVisible
  await element(screen->getByLabelText("Forum"))->toBeVisible
})

test("phone has some things hidden and a mobile nav", async () => {
  await viewport(600, 500)

  let screen = await render(
    <BrowserRouter>
      <NavbarPrimary />
    </BrowserRouter>,
  )

  await element(screen->getByText("Docs"))->toBeVisible
  await element(screen->getByText("Playground"))->notToBeVisible
  await element(screen->getByText("Blog"))->notToBeVisible
  await element(screen->getByText("Community"))->notToBeVisible

  await element(screen->getByLabelText("Github"))->notToBeVisible
  await element(screen->getByLabelText("X (formerly Twitter)"))->notToBeVisible
  await element(screen->getByLabelText("Bluesky"))->notToBeVisible
  await element(screen->getByLabelText("Forum"))->notToBeVisible
})
