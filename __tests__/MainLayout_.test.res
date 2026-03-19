open ReactRouter
open Vitest

test("desktop main layout renders children and footer", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="main-layout-wrapper">
        <MainLayout>
          <div dataTestId="main-content"> {React.string("Main page content goes here.")} </div>
        </MainLayout>
      </div>
    </BrowserRouter>,
  )

  let content = await screen->getByTestId("main-content")
  await element(content)->toBeVisible

  let community = await screen->getByText("Community")
  await element(community)->toBeVisible

  let wrapper = await screen->getByTestId("main-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-main-layout")
})

test("mobile main layout", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="main-layout-wrapper">
        <MainLayout>
          <div dataTestId="main-content"> {React.string("Main page content goes here.")} </div>
        </MainLayout>
      </div>
    </BrowserRouter>,
  )

  let content = await screen->getByTestId("main-content")
  await element(content)->toBeVisible

  let wrapper = await screen->getByTestId("main-layout-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-main-layout")
})
