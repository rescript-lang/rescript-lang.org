open Vitest

test(
  "code copy waits for the write, copies exact code, and permits retry after failure",
  async () => {
    let copied = ref(None)
    let complete = ref(_ => ())
    let writeClipboard = code => {
      copied := Some(code)
      Promise.make((resolve, _) => complete := resolve)
    }
    let screen = await render(<CodeCopyButton code="let answer = 42" writeClipboard />)
    let button = await screen->getByLabelText("Copy code")
    await button->click
    await element(button)->toBeDisabled
    expect(copied.contents)->toEqual(Some("let answer = 42"))
    complete.contents(Error(Clipboard.WriteFailed))
    let retry = await screen->getByLabelText("Copy failed, try again")
    await element(retry)->notToBeDisabled
    await retry->click
    complete.contents(Ok())
    let feedback = await screen->getByText("Copied to clipboard")
    await element(feedback)->toBeVisible
    await element(button)->toBeDisabled
    await screen->unmount
    await element(feedback)->notToBeInTheDocument
  },
)

test(
  "share copy writes the full URL and shows success only after the write completes",
  async () => {
    let copied = ref(None)
    let complete = ref(_ => ())
    let writeClipboard = url => {
      copied := Some(url)
      Promise.make((resolve, _) => complete := resolve)
    }
    let screen = await render(<PlaygroundShareButton writeClipboard />)
    let button = await screen->getByText("Copy Share Link")
    await button->click
    await element(button)->toBeDisabled
    expect(copied.contents)->toEqual(Some(window.location.href))
    complete.contents(Error(Clipboard.WriteFailed))
    let retry = await screen->getByText("Copy failed, try again")
    await element(retry)->notToBeDisabled
    await retry->click
    complete.contents(Ok())
    await element(await screen->getByText("Copied to clipboard!"))->toBeVisible
  },
)

test("a previous share write cannot change feedback for a new share link", async () => {
  let complete = ref(_ => ())
  let writeClipboard = _ => Promise.make((resolve, _) => complete := resolve)
  let screen = await render(<PlaygroundShareButton key="old-link" writeClipboard />)
  await (await screen->getByText("Copy Share Link"))->click
  await screen->rerender(<PlaygroundShareButton key="new-link" writeClipboard />)
  complete.contents(Ok())
  await element(await screen->getByText("Copy Share Link"))->notToBeDisabled
  await element(await screen->getByText("Copied to clipboard!"))->notToBeInTheDocument
})
