open Vitest

let firstLesson = GuideTestFixtures.firstLesson
let secondLesson = GuideTestFixtures.secondLesson
let guideLessons = GuideTestFixtures.guideLessons

test("checks expected output for the first lesson exercise", async () => {
  let matchingOutput = GuideCompilerFeedback.Output.make(
    ~status="Output",
    ~runtimeLogs=[{GuideCompilerFeedback.Output.level: #log, content: ["hello, world!"]}],
  )
  let nonMatchingOutput = GuideCompilerFeedback.Output.make(
    ~status="Output",
    ~runtimeLogs=[{GuideCompilerFeedback.Output.level: #log, content: ["goodbye"]}],
  )

  expect(firstLesson.exercise.initialCode)->toBe(`let greeting = "hello, world!"`)
  expect(
    GuideLesson.isExerciseComplete(~exercise=firstLesson.exercise, ~output=matchingOutput),
  )->toBe(true)
  expect(
    GuideLesson.isExerciseComplete(~exercise=firstLesson.exercise, ~output=nonMatchingOutput),
  )->toBe(false)
})

test("checks expected output for the function argument exercise", async () => {
  let matchingOutput = GuideCompilerFeedback.Output.make(
    ~status="Output",
    ~runtimeLogs=[{GuideCompilerFeedback.Output.level: #log, content: ["Hello, Spock!"]}],
  )
  let nonMatchingOutput = GuideCompilerFeedback.Output.make(
    ~status="Output",
    ~runtimeLogs=[{GuideCompilerFeedback.Output.level: #log, content: ["Hello, ReScript!"]}],
  )

  expect(secondLesson.exercise.initialCode)->toBe(`let greet = name => "Hello, " ++ name ++ "!"

let greeting = greet("ReScript")`)
  expect(
    GuideLesson.isExerciseComplete(~exercise=secondLesson.exercise, ~output=matchingOutput),
  )->toBe(true)
  expect(
    GuideLesson.isExerciseComplete(~exercise=secondLesson.exercise, ~output=nonMatchingOutput),
  )->toBe(false)
})

test("orders guide lessons by position", async () => {
  let ordered = [secondLesson, firstLesson]->GuideLesson.sort

  expect(ordered->Array.get(0)->Option.getOrThrow)->toBe(firstLesson)
  expect(ordered->Array.get(1)->Option.getOrThrow)->toBe(secondLesson)
})

test("resolves lesson hashes and falls back to the first lesson", async () => {
  expect(GuideLesson.indexForHash(~lessons=guideLessons, "#functions"))->toBe(1)
  expect(GuideLesson.indexForHash(~lessons=guideLessons, "functions"))->toBe(1)
  expect(GuideLesson.indexForHash(~lessons=guideLessons, "#missing"))->toBe(0)
  expect(GuideLesson.lessonAt(~lessons=guideLessons, 99))->toBe(firstLesson)
})
