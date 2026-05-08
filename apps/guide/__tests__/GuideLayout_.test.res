open Vitest

test("clamps resized pane dimensions", async () => {
  expect(GuideLayout.clampInstructionsWidth(~viewportWidth=1200.0, ~pointerX=120.0))->toBe(320.0)
  expect(GuideLayout.clampInstructionsWidth(~viewportWidth=1200.0, ~pointerX=900.0))->toBe(720.0)
  expect(GuideLayout.clampInstructionsWidth(~viewportWidth=1200.0, ~pointerX=520.0))->toBe(520.0)

  expect(GuideLayout.clampOutputHeight(~viewportHeight=900.0, ~pointerY=820.0))->toBe(160.0)
  expect(GuideLayout.clampOutputHeight(~viewportHeight=900.0, ~pointerY=120.0))->toBe(660.0)
  expect(GuideLayout.clampOutputHeight(~viewportHeight=900.0, ~pointerY=640.0))->toBe(260.0)
})

test("serializes pane sizes as guide CSS variables", async () => {
  let style = GuideLayout.paneSizesStyle({
    instructionsWidth: Some(420.0),
    outputHeight: 250.0,
  })

  expect(style->String.includes("--guide-instructions-width: 420px"))->toBe(true)
  expect(style->String.includes("--guide-output-height: 250px"))->toBe(true)
})

test("stores resized pane dimensions in local storage", async () => {
  GuideLayout.clearPaneSizes()

  GuideLayout.savePaneSizes({
    instructionsWidth: Some(420.0),
    outputHeight: 250.0,
  })

  let savedPaneSizes = GuideLayout.loadPaneSizes()
  let savedInstructionsWidth =
    savedPaneSizes.instructionsWidth->Option.map(width => width->Float.toString)->Option.getOrThrow

  expect(savedInstructionsWidth)->toBe("420")
  expect(savedPaneSizes.outputHeight)->toBe(250.0)

  GuideLayout.clearPaneSizes()
})

test("stores guide exercise code in local storage", async () => {
  let exerciseId = GuideTestFixtures.firstLesson.exercise.id
  GuideLayout.clearExerciseCode(exerciseId)

  GuideLayout.saveExerciseCode(~exerciseId, ~code="let voyager = 1701")

  expect(GuideLayout.loadExerciseCode(exerciseId)->Option.getOrThrow)->toBe("let voyager = 1701")

  GuideLayout.clearExerciseCode(exerciseId)
})

test("stores completed guide exercises in local storage", async () => {
  let exerciseId = GuideTestFixtures.firstLesson.exercise.id
  GuideLayout.clearCompletedExercises()

  GuideLayout.saveCompletedExercise(exerciseId)
  GuideLayout.saveCompletedExercise(exerciseId)

  let completedExerciseIds = GuideLayout.loadCompletedExerciseIds()

  expect(completedExerciseIds->Array.includes(exerciseId))->toBe(true)
  expect(completedExerciseIds->Array.length)->toBe(1)

  GuideLayout.clearCompletedExercises()
})
