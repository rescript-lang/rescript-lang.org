open Vitest

let firstLesson = GuideTestFixtures.firstLesson
let secondLesson = GuideTestFixtures.secondLesson
let guideLessonsWithFinal = GuideTestFixtures.guideLessonsWithFinal
let renderGuideHome = GuideTestFixtures.renderGuideHome
let renderGuideHomeWithDocsIntroNavigation = GuideTestFixtures.renderGuideHomeWithDocsIntroNavigation
let renderGuideHomeWithHistory = GuideTestFixtures.renderGuideHomeWithHistory

@module("vitest") external beforeEach: (unit => unit) => unit = "beforeEach"
@module("vitest") external afterEach: (unit => unit) => unit = "afterEach"

@module("./compilerFixture.js")
external waitForCompilerRequest: unit => promise<unit> = "waitForCompilerRequest"
@module("./compilerFixture.js") external failCompilerLoading: unit => unit = "failCompilerLoading"
@module("./compilerFixture.js")
external finishCompilerLoading: string => unit = "finishCompilerLoading"
@module("./compilerFixture.js")
external finishCompilerLoadingWithError: unit => unit = "finishCompilerLoadingWithError"
@module("./compilerFixture.js") external expectCompiled: string => unit = "expectCompiled"

let clearGuideState = () => {
  GuideLayout.clearCompletedExercises()
  GuideTestFixtures.guideLessonsWithFinal->Array.forEach(lesson =>
    GuideLayout.clearExerciseCode(lesson.exercise.id)
  )
  GuideLayout.removeLocalStorageItem(GuideLayout.themeStorageKey)
  GuideLayout.clearPaneSizes()
}

beforeEach(clearGuideState)
afterEach(clearGuideState)

let compilerData: GuideCompilerData.t = {
  bundleBaseUrl: "/test-compiler",
  versions: ["12.2.0"],
}

test("loads saved guide editor code into the editor", async () => {
  await viewport(1440, 900)
  let exerciseId = firstLesson.exercise.id
  GuideLayout.clearExerciseCode(exerciseId)
  GuideLayout.saveExerciseCode(~exerciseId, ~code="let sisko = \"emissary\"")

  let screen = await renderGuideHome()
  let savedCode = await screen->getByText("let sisko = \"emissary\"")

  await savedCode->element->toBeVisible

  GuideLayout.clearExerciseCode(exerciseId)
})

test("resets the current exercise code without clearing its completion", async () => {
  await viewport(1440, 900)
  let exerciseId = secondLesson.exercise.id
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(exerciseId)
  GuideLayout.saveExerciseCode(~exerciseId, ~code="let greeting = \"changed\"")
  GuideLayout.saveCompletedExercise(exerciseId)

  let screen = await renderGuideHome(~initialEntries=["/#functions"], ())
  let resetButton = await screen->getByLabelText("Reset exercise code")

  await resetButton->element->toBeVisible
  await resetButton->click

  let greetCode = await screen->getByText(`let greet = name => "Hello, " ++ name ++ "!"`)
  await greetCode->element->toBeVisible
  let greetingCode = await screen->getByText(`let greeting = greet("ReScript")`)
  await greetingCode->element->toBeVisible
  expect(GuideLayout.loadExerciseCode(exerciseId)->Option.isNone)->toBe(true)
  expect(GuideLayout.isExerciseCompleted(exerciseId))->toBe(true)

  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(exerciseId)
})

test("renders resize handles and toggles dark mode", async () => {
  await viewport(1440, 900)

  let screen = await renderGuideHome()
  let shell = await screen->getByTestId("guide-mvp")
  let columnHandle = await screen->getByTestId("guide-column-resize")
  let rowHandle = await screen->getByTestId("guide-row-resize")
  let themeToggle = await screen->getByLabelText("Switch to dark mode")

  await columnHandle->element->toBeVisible
  await rowHandle->element->toBeVisible
  await shell->element->toHaveClass("guide-theme-light")
  await themeToggle->click
  await shell->element->toHaveClass("guide-theme-dark")
})

test("requires a desktop browser on narrow viewports", async () => {
  await viewport(1023, 900)

  let screen = await renderGuideHome()
  let message = await screen->getByText("This interactive guide is available on desktop.")
  let shell = await screen->getByTestId("guide-mvp")

  await message->element->toBeVisible
  await shell->element->notToBeVisible
})

test("shows the guide workspace at the desktop minimum width", async () => {
  await viewport(1024, 900)

  let screen = await renderGuideHome()
  let message = await screen->getByText("This interactive guide is available on desktop.")
  let shell = await screen->getByTestId("guide-mvp")

  await message->element->notToBeVisible
  await shell->element->toBeVisible
})

test("keeps the first checkpoint pending without a compiler", async () => {
  await viewport(1440, 900)

  let screen = await renderGuideHome()
  await (await screen->getByText("Waiting for matching output"))->element->toBeVisible
  await (await screen->getByText("Next"))->element->toBeDisabled
  await (await screen->getByTestId("guide-output"))->element->toHaveTextContent("")
  expect(GuideLayout.isExerciseCompleted(firstLesson.exercise.id))->toBe(false)
})

test(
  "keeps the first checkpoint pending while the compiler loads and after loading fails",
  async () => {
    await viewport(1440, 900)

    let screen = await renderGuideHome(~compilerData, ())
    await waitForCompilerRequest()
    await (await screen->getByText("Waiting for matching output"))->element->toBeVisible
    await (await screen->getByText("Next"))->element->toBeDisabled
    expect(GuideLayout.isExerciseCompleted(firstLesson.exercise.id))->toBe(false)

    failCompilerLoading()

    await (await screen->getByText("Compiler setup failed"))->element->toBeVisible
    await (await screen->getByText("Waiting for matching output"))->element->toBeVisible
    await (await screen->getByText("Next"))->element->toBeDisabled
    expect(GuideLayout.isExerciseCompleted(firstLesson.exercise.id))->toBe(false)
  },
)

test(
  "completes and saves the first checkpoint after compiled code produces matching runtime output",
  async () => {
    await viewport(1440, 900)

    let screen = await renderGuideHome(~compilerData, ())
    await waitForCompilerRequest()
    await (await screen->getByText("Next"))->element->toBeDisabled

    finishCompilerLoading(`let greeting = "hello, world!";`)

    let checkpoint = await screen->getByText("Checkpoint complete")
    await checkpoint->element->toBeVisible
    let outputPanel = await screen->getByTestId("guide-output")
    await (await outputPanel->getByText("hello, world!"))->element->toBeVisible
    await (await screen->getByText("Next"))->element->notToBeDisabled
    expectCompiled(firstLesson.exercise.initialCode)
    expect(GuideLayout.isExerciseCompleted(firstLesson.exercise.id))->toBe(true)

    await screen->unmount
    let restoredScreen = await renderGuideHome()
    await (await restoredScreen->getByText("Checkpoint complete"))->element->toBeVisible
    await (await restoredScreen->getByText("Next"))->element->notToBeDisabled
    await (await restoredScreen->getByTestId("guide-output"))->element->toHaveTextContent("")
  },
)

test("keeps the first checkpoint pending when compilation fails", async () => {
  await viewport(1440, 900)

  let screen = await renderGuideHome(~compilerData, ())
  await waitForCompilerRequest()
  finishCompilerLoadingWithError()

  await (await screen->getByText("Compiler error"))->element->toBeVisible
  await (await screen->getByText("Compilation failed"))->element->toBeVisible
  await (await screen->getByText("Waiting for matching output"))->element->toBeVisible
  await (await screen->getByText("Next"))->element->toBeDisabled
  expectCompiled(firstLesson.exercise.initialCode)
  expect(GuideLayout.isExerciseCompleted(firstLesson.exercise.id))->toBe(false)
})

test(
  "keeps the first checkpoint pending when executed code produces different output",
  async () => {
    await viewport(1440, 900)
    let code = `let greeting = "goodbye"`
    GuideLayout.saveExerciseCode(~exerciseId=firstLesson.exercise.id, ~code)

    let screen = await renderGuideHome(~compilerData, ())
    await waitForCompilerRequest()
    finishCompilerLoading(`let greeting = "goodbye";`)

    let outputPanel = await screen->getByTestId("guide-output")
    await (await outputPanel->getByText("goodbye"))->element->toBeVisible
    await (await screen->getByText("Waiting for matching output"))->element->toBeVisible
    await (await screen->getByText("Next"))->element->toBeDisabled
    expectCompiled(code)
    expect(GuideLayout.isExerciseCompleted(firstLesson.exercise.id))->toBe(false)
  },
)

test("navigates to the function argument page", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
  GuideLayout.saveCompletedExercise(firstLesson.exercise.id)

  let screen = await renderGuideHome()
  let nextButton = await screen->getByText("Next")

  await nextButton->click

  await (await screen->getByText("Call A Function"))->element->toBeVisible
  await (await screen->getByText("Change the argument passed to greet from ReScript to Spock."))
  ->element
  ->toBeVisible
  let greetCode = await screen->getByText(`let greet = name => "Hello, " ++ name ++ "!"`)
  await greetCode->element->toBeVisible
  let greetingCode = await screen->getByText(`let greeting = greet("ReScript")`)
  await greetingCode->element->toBeVisible
  let checkpoint = await screen->getByText("Waiting for matching output")
  await checkpoint->element->toBeVisible

  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
})

test("shows Back before lesson forward actions and returns to the previous lesson", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(firstLesson.exercise.id)
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
  GuideLayout.saveCompletedExercise(firstLesson.exercise.id)

  let screen = await renderGuideHome(~initialEntries=["/#first-contact"], ())
  let firstLessonText = screen->container->textContent->Nullable.toOption->Option.getOrThrow
  let beforeNext = firstLessonText->String.split("Next")->Array.get(0)->Option.getOrThrow

  expect(beforeNext->String.includes("Back"))->toBe(true)
  await (await screen->getByText("Back"))->element->toBeVisible
  await (await screen->getByText("Next"))->click

  await (await screen->getByText("Call A Function"))->element->toBeVisible

  let secondLessonText = screen->container->textContent->Nullable.toOption->Option.getOrThrow
  let beforeDone = secondLessonText->String.split("Done")->Array.get(0)->Option.getOrThrow

  expect(beforeDone->String.includes("Back"))->toBe(true)
  await (await screen->getByText("Back"))->click
  await (await screen->getByText("Learn ReScript Guide"))->element->toBeVisible

  GuideLayout.clearExerciseCode(firstLesson.exercise.id)
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
})

test("enables Done on a completed final lesson", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
  GuideLayout.saveCompletedExercise(secondLesson.exercise.id)

  let screen = await renderGuideHome(~initialEntries=["/#functions"], ())
  let doneButton = await screen->getByText("Done")

  await doneButton->element->notToBeDisabled

  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
})

test("keeps Next disabled until the current checkpoint is complete", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)

  let screen = await render(
    <ReactRouter.MemoryRouter initialEntries=["/#functions"]>
      <GuideHome lessons=guideLessonsWithFinal />
    </ReactRouter.MemoryRouter>,
  )
  let nextButton = await screen->getByText("Next")

  await nextButton->element->toBeDisabled

  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
})

test("Done on a completed final lesson opens the ReScript docs intro", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
  GuideLayout.saveCompletedExercise(secondLesson.exercise.id)
  let openedUrl = ref("")

  let screen = await renderGuideHomeWithDocsIntroNavigation(
    url => openedUrl.contents = url,
    ~initialEntries=["/#functions"],
  )

  await (await screen->getByText("Done"))->click

  expect(openedUrl.contents)->toBe(GuideLessonNavigationHook.docsIntroUrl)

  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
})

test("history back returns to the previous guide lesson", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(firstLesson.exercise.id)
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
  GuideLayout.saveCompletedExercise(firstLesson.exercise.id)

  let screen = await renderGuideHomeWithHistory()

  await (await screen->getByText("Learn ReScript Guide"))->element->toBeVisible
  await (await screen->getByText("Next"))->click
  await (await screen->getByText("Call A Function"))->element->toBeVisible

  await (await screen->getByText("History back"))->click

  await (await screen->getByText("Learn ReScript Guide"))->element->toBeVisible

  GuideLayout.clearExerciseCode(firstLesson.exercise.id)
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
})

test("stretches the output surface to the full output panel", async () => {
  await viewport(1440, 900)

  let screen = await renderGuideHome()
  let output = await screen->getByTestId("guide-output")

  await output->element->toHaveClass("guide-output-frame")
})

test("renders the first guide MVP exercise with empty output", async () => {
  await viewport(1440, 900)

  let screen = await renderGuideHome()

  await (await screen->getByText("Learn ReScript Guide"))->element->toBeVisible
  await (
    await screen->getByText(
      "The editor runs automatically. For this first checkpoint, the final value should print hello, world! in the output log.",
    )
  )
  ->element
  ->toBeVisible
  await (await screen->getByText("Next"))->element->toBeVisible
  let editorCode = await screen->getByText("let greeting = \"hello, world!\"")
  await editorCode->element->toBeVisible
  let outputPanel = await screen->getByTestId("guide-output")
  await outputPanel->element->toHaveTextContent("")
})
