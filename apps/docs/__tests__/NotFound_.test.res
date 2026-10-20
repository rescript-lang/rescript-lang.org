open Vitest

module Location = {
  @react.component
  let make = () => {
    let {pathname} = ReactRouter.useLocation()
    <span dataTestId="current-path"> {React.string((pathname :> string))} </span>
  }
}

test("unknown documentation paths stay on the not-found page", async () => {
  let path = "/docs/react/does-not-exist"
  let screen = await render(
    <ReactRouter.MemoryRouter initialEntries=[path]>
      <NotFoundRoute.default />
      <Location />
    </ReactRouter.MemoryRouter>,
  )

  let heading = await screen->getByText("Page Not Found")
  await element(heading)->toBeVisible
  let currentPath = await screen->getByTestId("current-path")
  await element(currentPath)->toHaveTextContent(path)
})
