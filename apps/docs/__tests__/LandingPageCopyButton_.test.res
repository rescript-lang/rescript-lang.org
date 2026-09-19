open Vitest

test(
  "copy button writes its command and clears success feedback before copying again",
  async () => {
    let copiedCommand = ref(None)
    let writeClipboard = async code => {
      copiedCommand := Some(code)
      Ok()
    }
    let screen = await render(<LandingPageCopyButton code="npm install rescript" writeClipboard />)
    let button = await screen->getByLabelText("Copy npm install rescript command")

    await button->click

    let feedback = await screen->getByText("Copied!")
    await element(feedback)->toBeVisible
    expect(copiedCommand.contents)->toEqual(Some("npm install rescript"))
    await element(button)->toBeDisabled
    await element(button)->notToBeDisabled
    await element(feedback)->notToBeInTheDocument
    await button->click
    await element(feedback)->toBeVisible
  },
)

test("copy button exposes clipboard failure and allows retry", async () => {
  let shouldFail = ref(true)
  let writeClipboard = async _ => {
    if shouldFail.contents {
      shouldFail := false
      Error(Clipboard.WriteFailed)
    } else {
      Ok()
    }
  }
  let screen = await render(<LandingPageCopyButton code="npm install rescript" writeClipboard />)
  let button = await screen->getByLabelText("Copy npm install rescript command")

  await button->click

  let feedback = await screen->getByText("Could not copy. Try again.")
  await element(feedback)->toBeVisible
  await element(button)->notToBeDisabled
  await button->click

  let copied = await screen->getByText("Copied!")
  await element(copied)->toBeVisible
  await element(feedback)->notToBeInTheDocument
})

test("copy button disables duplicate writes until the clipboard operation settles", async () => {
  let complete = ref(_ => ())
  let writeClipboard = _ => Promise.make((resolve, _) => complete := resolve)
  let screen = await render(<LandingPageCopyButton code="npm install rescript" writeClipboard />)
  let button = await screen->getByLabelText("Copy npm install rescript command")

  await button->click
  await element(button)->toBeDisabled
  complete.contents(Ok())

  let feedback = await screen->getByText("Copied!")
  await element(feedback)->toBeVisible
})
