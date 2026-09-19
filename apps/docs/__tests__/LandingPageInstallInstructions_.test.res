open Vitest

test("install instructions update their class prop and keep copying available", async () => {
  let screen = await render(<LandingPageInstallInstructions className="initial-layout" />)
  let root = switch document->WebAPI.Document.querySelector(".initial-layout") {
  | Value(root) => root
  | Null => failwith("expected the install instructions root")
  }
  await element(root)->toHaveAttribute("class", "w-full max-w-400 initial-layout")

  await screen->rerender(<LandingPageInstallInstructions className="updated-layout" />)

  await element(root)->toHaveAttribute("class", "w-full max-w-400 updated-layout")
  let template = await screen->getByLabelText("Copy npx create-rescript-app command")
  await element(template)->toBeVisible

  await screen->rerender(<LandingPageInstallInstructions />)

  await element(root)->toHaveAttribute("class", "w-full max-w-400 ")
  let copy = await screen->getByLabelText("Copy npm install rescript command")
  await copy->click
  let feedback = await screen->getByText("Copied!")
  await element(feedback)->toBeVisible
})
