open Vitest

test("renders output diagnostics as error lines", async () => {
  let output = GuideCompilerFeedback.Output.make(
    ~status="Compiler error",
    ~diagnostics=["[E] Line 2, 7: Expected a string"],
  )

  let screen = await render(<GuideOutputPanel output />)
  let diagnostic = await screen->getByText("[E] Line 2, 7: Expected a string")

  await diagnostic->element->toHaveClass("guide-output-line-error")
})

test("renders runtime logs in the output panel", async () => {
  let output = GuideCompilerFeedback.Output.make(
    ~status="Output",
    ~runtimeLogs=[{GuideCompilerFeedback.Output.level: #log, content: ["52"]}],
  )

  let screen = await render(<GuideOutputPanel output />)

  await (await screen->getByText("Result"))->element->toBeVisible
  await (await screen->getByText("52"))->element->toBeVisible
})

test("does not render redundant output status inside the output panel", async () => {
  let output = GuideCompilerFeedback.Output.make(
    ~status="Output",
    ~runtimeLogs=[{GuideCompilerFeedback.Output.level: #log, content: ["52"]}],
  )

  let screen = await render(<GuideOutputPanel output />)
  let outputText = screen->container->textContent->Nullable.toOption->Option.getOrThrow

  expect(outputText->String.includes("Output"))->toBe(false)
})
