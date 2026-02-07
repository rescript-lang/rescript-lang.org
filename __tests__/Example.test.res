open Vitest

module Example = {
  @react.component
  let make = () => <div> {React.string("testing")} </div>
}

test("basic assertions", async () => {
  expect("foo")->toBe("foo")

  expect(true)->toBe(true)
})

test("component rendering", async () => {
  let screen = await render(<Example />)

  await element(screen->getByText("testing"))->toBeVisible
})
