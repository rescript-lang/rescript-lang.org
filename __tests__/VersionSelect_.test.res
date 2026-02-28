open Vitest

test("renders current version label", async () => {
  let screen = await render(<VersionSelect />)

  let el = await screen->getByTestId("version-select")
  await element(el)->toBeVisible

  let label = await screen->getByText("v12 (latest)")
  await element(label)->toBeVisible
})

test("clicking button shows older versions", async () => {
  let screen = await render(<VersionSelect />)

  // Menu should be hidden initially
  let v11 = await screen->getByText("v11")
  await element(v11)->notToBeVisible

  // Click the trigger button
  let button = await screen->getByRole(#button)
  await button->click

  // Older versions should now be visible
  let v11After = await screen->getByText("v11")
  await element(v11After)->toBeVisible

  let v9 = await screen->getByText("v9.1 - v10.1")
  await element(v9)->toBeVisible

  let v8 = await screen->getByText("v8.2 - v9.0")
  await element(v8)->toBeVisible

  let v6 = await screen->getByText("v6.0 - v8.1")
  await element(v6)->toBeVisible
})

test("clicking button again closes older versions", async () => {
  let screen = await render(<VersionSelect />)

  let button = await screen->getByRole(#button)

  // Open
  await button->click
  let v11 = await screen->getByText("v11")
  await element(v11)->toBeVisible

  // Close
  await button->click
  let v11After = await screen->getByText("v11")
  await element(v11After)->notToBeVisible
})

test("multiple instances have unique popover IDs", async () => {
  let screen = await render(
    <div>
      <div dataTestId="first">
        <VersionSelect />
      </div>
      <div dataTestId="second">
        <VersionSelect />
      </div>
    </div>,
  )

  let first = await screen->getByTestId("first")
  let second = await screen->getByTestId("second")

  // Click the button in the first instance
  let firstButton = await first->getByRole(#button)
  await firstButton->click

  // First instance menu should be visible
  let firstV11 = await first->getByText("v11")
  await element(firstV11)->toBeVisible

  // Second instance menu should remain hidden
  let secondV11 = await second->getByText("v11")
  await element(secondV11)->notToBeVisible
})
