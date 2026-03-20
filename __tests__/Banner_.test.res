open Vitest

test("renders banner with content", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="banner-wrapper">
      <Banner> {React.string("ReScript v12 is now available!")} </Banner>
    </div>,
  )

  let text = await screen->getByText("ReScript v12 is now available!")
  await element(text)->toBeVisible

  let wrapper = await screen->getByTestId("banner-wrapper")
  await element(wrapper)->toMatchScreenshot("banner-with-content")
})

test("mobile banner", async () => {
  await viewport(600, 500)

  let screen = await render(
    <div dataTestId="banner-wrapper">
      <Banner> {React.string("ReScript v12 is now available!")} </Banner>
    </div>,
  )

  let text = await screen->getByText("ReScript v12 is now available!")
  await element(text)->toBeVisible

  let wrapper = await screen->getByTestId("banner-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-banner")
})
