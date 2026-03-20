open ReactRouter
open Vitest

test("desktop footer shows all sections and links", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="footer-wrapper">
        <Footer />
      </div>
    </BrowserRouter>,
  )

  let community = await screen->getByText("Community")
  await element(community)->toBeVisible

  let association = await screen->getByText("ReScript Association")
  await element(association)->toBeVisible

  let aboutSection = await screen->getByText("About")
  await element(aboutSection)->toBeVisible

  let findUsSection = await screen->getByText("Find us on")
  await element(findUsSection)->toBeVisible

  let wrapper = await screen->getByTestId("footer-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-footer")
})

test("mobile footer stacks sections vertically", async () => {
  await viewport(600, 800)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="footer-wrapper">
        <Footer />
      </div>
    </BrowserRouter>,
  )

  let community = await screen->getByText("Community")
  await element(community)->toBeVisible

  let association = await screen->getByText("ReScript Association")
  await element(association)->toBeVisible

  let wrapper = await screen->getByTestId("footer-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-footer")
})
