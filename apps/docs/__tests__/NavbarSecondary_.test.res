open ReactRouter
open Vitest

test("desktop secondary navbar shows all doc section links", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <NavbarSecondary />
    </MemoryRouter>,
  )

  let navbar = await screen->getByTestId("navbar-secondary")

  await element(await navbar->getByText("Language Manual"))->toBeVisible
  await element(await navbar->getByText("API"))->toBeVisible
  await element(await navbar->getByText("Syntax Lookup"))->toBeVisible
  await element(await navbar->getByText("React"))->toBeVisible

  await element(navbar)->toMatchScreenshot("desktop-navbar-secondary")
})

test("mobile secondary navbar shows all links", async () => {
  await viewport(600, 500)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/manual/introduction"]>
      <NavbarSecondary />
    </MemoryRouter>,
  )

  let navbar = await screen->getByTestId("navbar-secondary")

  await element(await navbar->getByText("Language Manual"))->toBeVisible
  await element(await navbar->getByText("API"))->toBeVisible
  await element(await navbar->getByText("Syntax Lookup"))->toBeVisible
  await element(await navbar->getByText("React"))->toBeVisible

  await element(navbar)->toMatchScreenshot("mobile-navbar-secondary")
})

test("secondary navbar highlights active section", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <MemoryRouter initialEntries=["/docs/react/introduction"]>
      <NavbarSecondary />
    </MemoryRouter>,
  )

  let navbar = await screen->getByTestId("navbar-secondary")

  await element(await navbar->getByText("React"))->toBeVisible
  await element(await navbar->getByText("Language Manual"))->toBeVisible

  await element(navbar)->toMatchScreenshot("desktop-navbar-secondary-react-active")
})
