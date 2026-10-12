open Vitest

let sourcePath = "test/lesson.mdx"

let completeLesson = `---
position: 1
id: test-lesson
missionLabel: Test mission
title: Test lesson
description: A test lesson.
exercise:
  id: test-lesson/example
  title: Test exercise
  initialCode: |
    let answer = 42
  expectedOutput: "42"
---

Test body.`

let completeLessonResult = () =>
  switch GuideLessonFrontmatter.parse(~raw=completeLesson, ~sourcePath) {
  | Ok(lesson) => lesson
  | Error(message) => throw(Failure(message))
  }

test("parses complete guide lesson frontmatter", async () => {
  expect(GuideLessonFrontmatter.parse(~raw=completeLesson, ~sourcePath))->toEqual(
    Ok({
      GuideLesson.id: "test-lesson",
      position: 1,
      sourcePath,
      missionLabel: "Test mission",
      title: "Test lesson",
      description: "A test lesson.",
      content: "Test body.",
      exercise: {
        id: "test-lesson/example",
        title: "Test exercise",
        initialCode: "let answer = 42",
        check: ExpectedOutput("42"),
      },
    }),
  )
})

test("rejects guide lesson frontmatter without a lesson id", async () => {
  let invalidLesson = completeLesson->String.replace("id: test-lesson\n", "")

  expect(GuideLessonFrontmatter.parse(~raw=invalidLesson, ~sourcePath))->toEqual(
    Error(`Guide lesson ${sourcePath} frontmatter "id" must be a non-empty string.`),
  )
})

test("collects parsed guide lessons", async () => {
  let firstLesson = completeLessonResult()
  let secondLesson = {
    ...firstLesson,
    id: "second-lesson",
    sourcePath: "test/second-lesson.mdx",
    exercise: {...firstLesson.exercise, id: "second-lesson/example"},
  }

  expect(GuideLessonContent.collect([Ok(firstLesson), Ok(secondLesson)]))->toEqual(
    Ok([firstLesson, secondLesson]),
  )
})

test("preserves the first frontmatter error while collecting lessons", async () => {
  let firstLesson = completeLessonResult()

  expect(
    GuideLessonContent.collect([Ok(firstLesson), Error("first error"), Error("second error")]),
  )->toEqual(Error("first error"))
})

test("accepts a guide lesson collection with distinct identifiers and positions", async () => {
  let firstLesson = completeLessonResult()
  let secondLesson = {
    ...firstLesson,
    id: "second-lesson",
    position: 2,
    sourcePath: "test/second-lesson.mdx",
    exercise: {...firstLesson.exercise, id: "second-lesson/example"},
  }

  expect(GuideLessonFrontmatter.validate([firstLesson, secondLesson]))->toEqual(Ok())
})

test("rejects duplicate guide lesson ids", async () => {
  let firstLesson = completeLessonResult()
  let secondLesson = {...firstLesson, sourcePath: "test/second-lesson.mdx"}

  expect(GuideLessonFrontmatter.validate([firstLesson, secondLesson]))->toEqual(
    Error(
      GuideLessonFrontmatter.DuplicateLessonId({
        value: "test-lesson",
        sourcePaths: ["test/lesson.mdx", "test/second-lesson.mdx"],
      }),
    ),
  )
})

test("rejects duplicate guide exercise ids", async () => {
  let firstLesson = completeLessonResult()
  let secondLesson = {
    ...firstLesson,
    id: "second-lesson",
    sourcePath: "test/second-lesson.mdx",
  }

  expect(GuideLessonFrontmatter.validate([firstLesson, secondLesson]))->toEqual(
    Error(
      GuideLessonFrontmatter.DuplicateExerciseId({
        value: "test-lesson/example",
        sourcePaths: ["test/lesson.mdx", "test/second-lesson.mdx"],
      }),
    ),
  )
})

test("rejects duplicate guide lesson positions", async () => {
  let firstLesson = completeLessonResult()
  let secondLesson = {
    ...firstLesson,
    id: "second-lesson",
    sourcePath: "test/second-lesson.mdx",
    exercise: {...firstLesson.exercise, id: "second-lesson/example"},
  }

  expect(GuideLessonFrontmatter.validate([firstLesson, secondLesson]))->toEqual(
    Error(
      GuideLessonFrontmatter.DuplicatePosition({
        value: "1",
        sourcePaths: ["test/lesson.mdx", "test/second-lesson.mdx"],
      }),
    ),
  )
})
