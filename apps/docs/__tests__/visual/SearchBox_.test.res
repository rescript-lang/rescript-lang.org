open Vitest

test("renders with placeholder text", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="searchbox-wrapper">
      <SearchBox
        value="" placeholder="Search for something..." onClear={() => ()} onValueChange={_ => ()}
      />
    </div>,
  )

  let wrapper = await screen->getByTestId("searchbox-wrapper")
  await element(wrapper)->toMatchScreenshot("searchbox-empty")
})

test("renders with a value", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="searchbox-wrapper">
      <SearchBox value="@as" placeholder="Search..." onClear={() => ()} onValueChange={_ => ()} />
    </div>,
  )

  let wrapper = await screen->getByTestId("searchbox-wrapper")
  await element(wrapper)->toMatchScreenshot("searchbox-with-value")
})
