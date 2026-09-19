open Vitest

let images = ["/lp/community-3.avif", "/lp/community-2.avif", "/lp/community-1.avif"]

test(
  "gallery selectors show their photo and the next control wraps after the last photo",
  async () => {
    let screen = await render(<ImageGallery imgSrcs=images />)
    let first = await screen->getByLabelText("Show community photo 1")
    let third = await screen->getByLabelText("Show community photo 3")
    let next = await screen->getByLabelText("Next community photo")

    await element(first)->toHaveAttribute("aria-pressed", "true")
    await third->click
    await element(third)->toHaveAttribute("aria-pressed", "true")
    let lastImage = await screen->getByAltText("ReScript community photo 3")
    await element(lastImage)->toHaveAttribute("src", "/lp/community-1.avif")
    await next->click

    await element(first)->toHaveAttribute("aria-pressed", "true")
    await element(third)->toHaveAttribute("aria-pressed", "false")
    let firstImage = await screen->getByAltText("ReScript community photo 1")
    await element(firstImage)->toHaveAttribute("src", "/lp/community-3.avif")
  },
)

test("gallery renders no controls for an empty image list", async () => {
  let screen = await render(<ImageGallery imgSrcs=[] />)
  expect(screen->container->textContent->Nullable.toOption)->toEqual(Some(""))
  let next = await screen->getByLabelText("Next community photo")
  await element(next)->notToBeInTheDocument
})

test("gallery returns to the first image when the selected image is removed", async () => {
  let screen = await render(<ImageGallery imgSrcs=images />)
  let third = await screen->getByLabelText("Show community photo 3")
  await third->click

  await screen->rerender(<ImageGallery imgSrcs=["/lp/community-3.avif"] />)

  let firstImage = await screen->getByAltText("ReScript community photo 1")
  await element(firstImage)->toHaveAttribute("src", "/lp/community-3.avif")
  let next = await screen->getByLabelText("Next community photo")
  await next->click
  await element(firstImage)->toHaveAttribute("src", "/lp/community-3.avif")
})

test("gallery keeps the first image selected when a shortened list grows again", async () => {
  let screen = await render(<ImageGallery imgSrcs=images />)
  let third = await screen->getByLabelText("Show community photo 3")
  await third->click

  await screen->rerender(<ImageGallery imgSrcs=["/lp/community-3.avif"] />)
  let first = await screen->getByLabelText("Show community photo 1")
  await element(first)->toHaveAttribute("aria-pressed", "true")

  await screen->rerender(<ImageGallery imgSrcs=images />)

  await element(first)->toHaveAttribute("aria-pressed", "true")
  await element(third)->toHaveAttribute("aria-pressed", "false")
  let firstImage = await screen->getByAltText("ReScript community photo 1")
  await element(firstImage)->toHaveAttribute("src", "/lp/community-3.avif")
})

test("gallery keeps the first image selected after an empty list is restored", async () => {
  let screen = await render(<ImageGallery imgSrcs=images />)
  let third = await screen->getByLabelText("Show community photo 3")
  await third->click

  await screen->rerender(<ImageGallery imgSrcs=[] />)
  let next = await screen->getByLabelText("Next community photo")
  await element(next)->notToBeInTheDocument

  await screen->rerender(<ImageGallery imgSrcs=images />)

  let first = await screen->getByLabelText("Show community photo 1")
  await element(first)->toHaveAttribute("aria-pressed", "true")
  await element(third)->toHaveAttribute("aria-pressed", "false")
  let firstImage = await screen->getByAltText("ReScript community photo 1")
  await element(firstImage)->toHaveAttribute("src", "/lp/community-3.avif")
})
