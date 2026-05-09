open Vitest

let firstLesson = GuideTestFixtures.firstLesson
let secondLesson = GuideTestFixtures.secondLesson
let guideLessonsWithFinal = GuideTestFixtures.guideLessonsWithFinal
let renderGuideHome = GuideTestFixtures.renderGuideHome
let renderGuideHomeWithDocsIntroNavigation = GuideTestFixtures.renderGuideHomeWithDocsIntroNavigation
let renderGuideHomeInBrowser = GuideTestFixtures.renderGuideHomeInBrowser

test("loads saved guide editor code into the editor", async () => {
  await viewport(1440, 900)
  let exerciseId = firstLesson.exercise.id
  GuideLayout.clearExerciseCode(exerciseId)
  GuideLayout.saveExerciseCode(~exerciseId, ~code="let sisko = \"emissary\"")

  let screen = await renderGuideHome()
  let editor = await screen->getByTestId("guide-code-editor")

  await editor->element->toHaveTextContent("let sisko = \"emissary\"")

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

test("shows a minimum screen size message on narrow viewports", async () => {
  await viewport(800, 900)

  let screen = await renderGuideHome()
  let message = await screen->getByText("This guide needs a wider screen.")

  await message->element->toBeVisible
})

test("shows the first checkpoint as complete when output matches", async () => {
  await viewport(1440, 900)

  let screen = await renderGuideHome()
  let checkpoint = await screen->getByTestId("guide-check-status")

  await checkpoint->element->toHaveTextContent("Checkpoint complete")
})

test("navigates to the function argument page", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)

  let screen = await renderGuideHome()
  let nextButton = await screen->getByText("Next")

  await nextButton->click

  await (await screen->getByText("Call A Function"))->element->toBeVisible
  await (await screen->getByText("Change the argument passed to greet from ReScript to Spock."))
  ->element
  ->toBeVisible
  let editor = await screen->getByTestId("guide-code-editor")
  await editor->element->toHaveTextContent(`let greet = name => "Hello, " ++ name ++ "!"`)
  await editor->element->toHaveTextContent(`let greeting = greet("ReScript")`)
  let checkpoint = await screen->getByTestId("guide-check-status")
  await checkpoint->element->toHaveTextContent("Waiting for matching output")

  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
})

let guideTestUrl = hash => window.location.pathname ++ window.location.search ++ hash

let resetGuideTestUrl = () =>
  WebAPI.History.replaceState(window.history, ~data=JSON.Null, ~unused="", ~url=guideTestUrl(""))

test("shows Back before lesson forward actions and returns to the previous lesson", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(firstLesson.exercise.id)
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)

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

test("browser back returns to the previous guide lesson", async () => {
  await viewport(1440, 900)
  GuideLayout.clearCompletedExercises()
  GuideLayout.clearExerciseCode(firstLesson.exercise.id)
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
  WebAPI.History.replaceState(
    window.history,
    ~data=JSON.Null,
    ~unused="",
    ~url=guideTestUrl("#guide-test-start"),
  )
  WebAPI.History.pushState(
    window.history,
    ~data=JSON.Null,
    ~unused="",
    ~url=guideTestUrl("#first-contact"),
  )

  let screen = await renderGuideHomeInBrowser()

  await (await screen->getByText("Learn ReScript Guide"))->element->toBeVisible
  await (await screen->getByText("Next"))->click
  await (await screen->getByText("Call A Function"))->element->toBeVisible

  WebAPI.History.back(window.history)

  await (await screen->getByText("Learn ReScript Guide"))->element->toBeVisible

  GuideLayout.clearExerciseCode(firstLesson.exercise.id)
  GuideLayout.clearExerciseCode(secondLesson.exercise.id)
  resetGuideTestUrl()
})

test("stretches the output surface to the full output panel", async () => {
  await viewport(1440, 900)

  let screen = await renderGuideHome()
  let output = await screen->getByTestId("guide-output")

  await output->element->toHaveClass("guide-output-frame")
})

test("renders the first guide MVP exercise and output", async () => {
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
  let editor = await screen->getByTestId("guide-code-editor")
  await editor->element->toBeVisible
  await editor->element->toHaveTextContent("let greeting = \"hello, world!\"")
  let output = await screen->getByTestId("guide-output")
  await output->element->toBeVisible

  await output->element->toHaveTextContent("hello, world!")
})
