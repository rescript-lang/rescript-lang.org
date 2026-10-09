open Vitest

let firstLesson: GuideLesson.t = {
  id: "first-contact",
  position: 1,
  missionLabel: "Mission 01",
  title: "Learn ReScript Guide",
  content: `This interactive guide introduces ReScript through small examples, steady practice, and a live output log.

The editor runs automatically. For this first checkpoint, the final value should print \`hello, world!\` in the output log.`,
  exercise: {
    id: "first-contact/greeting",
    initialCode: `let greeting = "hello, world!"`,
    expectedOutput: "hello, world!",
  },
}

let secondLesson: GuideLesson.t = {
  id: "functions",
  position: 2,
  missionLabel: "Mission 02",
  title: "Call A Function",
  content: `Functions take values as input and return a new value.

Change the argument passed to \`greet\` from \`ReScript\` to \`Spock\`.`,
  exercise: {
    id: "functions/greet-spock",
    initialCode: `let greet = name => "Hello, " ++ name ++ "!"

let greeting = greet("ReScript")`,
    expectedOutput: "Hello, Spock!",
  },
}

let finalLesson: GuideLesson.t = {
  id: "final-check",
  position: 3,
  missionLabel: "Mission 03",
  title: "Final Check",
  content: `Complete the final checkpoint.`,
  exercise: {
    id: "final-check/done",
    initialCode: `let done = true`,
    expectedOutput: "true",
  },
}

let guideLessons = [firstLesson, secondLesson]
let guideLessonsWithFinal = [firstLesson, secondLesson, finalLesson]

let renderGuideHome = (~initialEntries=["/"], ()) =>
  render(
    <ReactRouter.MemoryRouter initialEntries>
      <GuideHome lessons=guideLessons />
    </ReactRouter.MemoryRouter>,
  )

let renderGuideHomeWithDocsIntroNavigation = (goToDocsIntro, ~initialEntries=["/"]) =>
  render(
    <ReactRouter.MemoryRouter initialEntries>
      <GuideHome lessons=guideLessons goToDocsIntro />
    </ReactRouter.MemoryRouter>,
  )

let renderGuideHomeInBrowser = () =>
  render(
    <ReactRouter.BrowserRouter>
      <GuideHome lessons=guideLessons />
    </ReactRouter.BrowserRouter>,
  )
