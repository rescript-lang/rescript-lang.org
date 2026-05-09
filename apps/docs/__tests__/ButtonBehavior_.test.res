open Vitest

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
