open Vitest

test("maps compiler diagnostics into editor errors", async () => {
  let locMsg: RescriptCompilerApi.LocMsg.t = {
    fullMsg: "Full compiler error",
    shortMsg: "Expected a string",
    row: 2,
    column: 7,
    endRow: 2,
    endColumn: 12,
  }

  let editorError = GuideCompilerFeedback.locMsgToEditorError(~kind=#Error, locMsg)

  expect(editorError.row)->toBe(2)
  expect(editorError.column)->toBe(7)
  expect(editorError.endRow)->toBe(2)
  expect(editorError.endColumn)->toBe(12)
  expect(editorError.text)->toBe("Expected a string")

  let outputLine =
    GuideCompilerFeedback.compileFailToOutputLines(TypecheckErr([locMsg]))
    ->Array.get(0)
    ->Option.getOrThrow
  expect(outputLine)->toBe("[E] Line 2, 7: Expected a string")
})

test("maps compiler type hints into hover hints", async () => {
  let typeHint = RescriptCompilerApi.TypeHint.Binding({
    start: {line: 1, col: 4},
    end: {line: 1, col: 12},
    hint: "string",
  })

  let hoverHint =
    GuideCompilerFeedback.typeHintsToHoverHints([typeHint])->Array.get(0)->Option.getOrThrow

  expect(hoverHint.start.line)->toBe(1)
  expect(hoverHint.start.col)->toBe(4)
  expect(hoverHint.end.line)->toBe(1)
  expect(hoverHint.end.col)->toBe(12)
  expect(hoverHint.hint)->toBe("string")
})

test("keeps the previous output while a successful compile waits for runtime logs", async () => {
  let typeHint = RescriptCompilerApi.TypeHint.Binding({
    start: {line: 1, col: 4},
    end: {line: 1, col: 12},
    hint: "string",
  })

  let outputUpdate = GuideCompilerFeedback.compilationResultToOutputUpdate(
    Success({
      jsCode: "let value = 52;",
      warnings: [],
      typeHints: [typeHint],
      time: 1.0,
    }),
  )

  expect(outputUpdate->Option.isNone)->toBe(true)
})

test("shows compiler errors as output updates", async () => {
  let locMsg: RescriptCompilerApi.LocMsg.t = {
    fullMsg: "Full compiler error",
    shortMsg: "Expected a string",
    row: 2,
    column: 7,
    endRow: 2,
    endColumn: 12,
  }

  let output =
    GuideCompilerFeedback.compilationResultToOutputUpdate(
      Fail(TypecheckErr([locMsg])),
    )->Option.getOrThrow

  expect(output.status)->toBe("Compiler error")
  expect(output.diagnostics->Array.get(0)->Option.getOrThrow)->toBe(
    "[E] Line 2, 7: Expected a string",
  )
})
