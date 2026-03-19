open ReactRouter
open Vitest

test("desktop API overview shows sidebar categories and content", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="api-overview-wrapper">
        <ApiOverviewLayout.Docs>
          <div> {React.string("API documentation content.")} </div>
        </ApiOverviewLayout.Docs>
      </div>
    </BrowserRouter>,
  )

  let overview = await screen->getByText("Overview")
  await element(overview)->toBeVisible

  let introduction = await screen->getByText("Introduction")
  await element(introduction)->toBeVisible

  let stdlib = await screen->getByText("Stdlib")
  await element(stdlib)->toBeVisible

  let additionalLibraries = await screen->getByText("Additional Libraries")
  await element(additionalLibraries)->toBeVisible

  let belt = await screen->getByText("Belt")
  await element(belt)->toBeVisible

  let dom = await screen->getByText("Dom")
  await element(dom)->toBeVisible

  let mainContent = await screen->getByTestId("side-layout-children")
  await element(mainContent)->toBeVisible

  let wrapper = await screen->getByTestId("api-overview-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-api-overview")
})

test("mobile API overview hides sidebar", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="api-overview-wrapper">
        <ApiOverviewLayout.Docs>
          <div> {React.string("API documentation content.")} </div>
        </ApiOverviewLayout.Docs>
      </div>
    </BrowserRouter>,
  )

  let introduction = await screen->getByText("Introduction")
  await element(introduction)->notToBeVisible

  let stdlib = await screen->getByText("Stdlib")
  await element(stdlib)->notToBeVisible

  let belt = await screen->getByText("Belt")
  await element(belt)->notToBeVisible

  let wrapper = await screen->getByTestId("api-overview-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-api-overview")
})

test("desktop API overview shows all category items", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="api-overview-wrapper">
        <ApiOverviewLayout.Docs>
          <div>
            <Markdown.H1> {React.string("API Reference")} </Markdown.H1>
            <Markdown.P> {React.string("Welcome to the ReScript API documentation.")} </Markdown.P>
          </div>
        </ApiOverviewLayout.Docs>
      </div>
    </BrowserRouter>,
  )

  let apiTitle = await screen->getByText("API Reference")
  await element(apiTitle)->toBeVisible

  let apiDescription = await screen->getByText("Welcome to the ReScript API documentation.")
  await element(apiDescription)->toBeVisible

  let wrapper = await screen->getByTestId("api-overview-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-api-overview-with-content")
})

test("tablet API overview", async () => {
  await viewport(900, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="api-overview-wrapper">
        <ApiOverviewLayout.Docs>
          <div> {React.string("API documentation content.")} </div>
        </ApiOverviewLayout.Docs>
      </div>
    </BrowserRouter>,
  )

  let overview = await screen->getByText("Overview")
  await element(overview)->toBeVisible

  let wrapper = await screen->getByTestId("api-overview-wrapper")
  await element(wrapper)->toMatchScreenshot("tablet-api-overview")
})
