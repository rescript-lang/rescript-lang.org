open Vitest

test("renders PrimaryRed button", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="button-wrapper">
      <Button kind=PrimaryRed> {React.string("Click Me")} </Button>
    </div>,
  )

  let btn = await screen->getByText("Click Me")
  await element(btn)->toBeVisible

  let wrapper = await screen->getByTestId("button-wrapper")
  await element(wrapper)->toMatchScreenshot("button-primary-red")
})

test("renders PrimaryBlue button", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="button-wrapper">
      <Button kind=PrimaryBlue> {React.string("Blue Action")} </Button>
    </div>,
  )

  let btn = await screen->getByText("Blue Action")
  await element(btn)->toBeVisible

  let wrapper = await screen->getByTestId("button-wrapper")
  await element(wrapper)->toMatchScreenshot("button-primary-blue")
})

test("renders SecondaryRed button", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="button-wrapper">
      <Button kind=SecondaryRed> {React.string("Secondary")} </Button>
    </div>,
  )

  let btn = await screen->getByText("Secondary")
  await element(btn)->toBeVisible

  let wrapper = await screen->getByTestId("button-wrapper")
  await element(wrapper)->toMatchScreenshot("button-secondary-red")
})

test("renders Small button", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="button-wrapper">
      <Button size=Small> {React.string("Small Button")} </Button>
    </div>,
  )

  let btn = await screen->getByText("Small Button")
  await element(btn)->toBeVisible

  let wrapper = await screen->getByTestId("button-wrapper")
  await element(wrapper)->toMatchScreenshot("button-small")
})

test("calls onClick when clicked", async () => {
  await viewport(1440, 500)

  let handleClick = fn()

  let screen = await render(
    <div dataTestId="button-wrapper">
      <Button onClick=handleClick> {React.string("Clickable")} </Button>
    </div>,
  )

  let btn = await screen->getByText("Clickable")
  await btn->click

  expect(handleClick)->toHaveBeenCalled
})
