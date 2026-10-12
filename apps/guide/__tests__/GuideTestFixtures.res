open Vitest

let firstLesson: GuideLesson.t = {
  id: "first-contact",
  position: 1,
  sourcePath: "app/lessons/01-first-contact.mdx",
  missionLabel: "Mission 01",
  title: "Learn ReScript Guide",
  description: "Run a small ReScript program and inspect its output.",
  content: `This interactive guide introduces ReScript through small examples, steady practice, and a live output log.

The editor runs automatically. For this first checkpoint, the final value should print \`hello, world!\` in the output log.`,
  exercise: {
    id: "first-contact/greeting",
    title: "Send a greeting",
    initialCode: `let greeting = "hello, world!"`,
    check: ExpectedOutput("hello, world!"),
  },
}

let secondLesson: GuideLesson.t = {
  id: "functions",
  position: 2,
  sourcePath: "app/lessons/02-functions.mdx",
  missionLabel: "Mission 02",
  title: "Call A Function",
  description: "Change a function call and inspect the result.",
  content: `Functions take values as input and return a new value.

Change the argument passed to \`greet\` from \`ReScript\` to \`Spock\`.`,
  exercise: {
    id: "functions/greet-spock",
    title: "Greet Spock",
    initialCode: `let greet = name => "Hello, " ++ name ++ "!"

let greeting = greet("ReScript")`,
    check: ExpectedOutput("Hello, Spock!"),
  },
}

let finalLesson: GuideLesson.t = {
  id: "final-check",
  position: 3,
  sourcePath: "app/lessons/03-final-check.mdx",
  missionLabel: "Mission 03",
  title: "Final Check",
  description: "Finish the guide.",
  content: `Complete the final checkpoint.`,
  exercise: {
    id: "final-check/done",
    title: "Finish",
    initialCode: `let done = true`,
    check: ExpectedOutput("true"),
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
