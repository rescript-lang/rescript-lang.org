open Vitest

test("renders subtle tag with text", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="tag-wrapper">
      <Tag text="ReScript" />
    </div>,
  )

  let tag = await screen->getByText("ReScript")
  await element(tag)->toBeVisible

  let wrapper = await screen->getByTestId("tag-wrapper")
  await element(wrapper)->toMatchScreenshot("tag-subtle")
})

test("renders multiple tags side by side", async () => {
  await viewport(1440, 500)

  let screen = await render(
    <div dataTestId="tags-wrapper" className="flex gap-2">
      <Tag text="v12" />
      <Tag text="Release" />
      <Tag text="Featured" />
    </div>,
  )

  let v12 = await screen->getByText("v12")
  await element(v12)->toBeVisible

  let release = await screen->getByText("Release")
  await element(release)->toBeVisible

  let featured = await screen->getByText("Featured")
  await element(featured)->toBeVisible

  let wrapper = await screen->getByTestId("tags-wrapper")
  await element(wrapper)->toMatchScreenshot("tags-multiple")
})
