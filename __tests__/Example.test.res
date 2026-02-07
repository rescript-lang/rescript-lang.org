open Vitest

module Example = {
  @react.component
  let make = (~handleClick) =>
    <div>
      <button onClick=handleClick> {React.string("testing")} </button>
    </div>
}

test("basic assertions", async () => {
  expect("foo")->toBe("foo")

  expect(true)->toBe(true)
})

test("component rendering", async () => {
  let callback = fn()
  let screen = await render(<Example handleClick=callback />)

  await element(screen->getByText("testing"))->toBeVisible

  let button = await screen->getByRole(#button)

  await button->click

  expect(callback)->toHaveBeenCalled
})
