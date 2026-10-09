open Vitest

let sourcePath = "test/lesson.mdx"

let completeLesson = `---
position: 1
id: test-lesson
missionLabel: Test mission
title: Test lesson
exercise:
  id: test-lesson/example
  initialCode: |
    let answer = 42
  expectedOutput: "42"
---

Test body.`

let parse = raw => GuideLessonFrontmatter.parse(~raw, ~sourcePath)
let completeLessonResult = () => completeLesson->parse->Result.getOrThrow

let secondLesson = (
  ~id="second-lesson",
  ~position=2,
  ~exerciseId="second-lesson/example",
  first,
) => {
  GuideLessonFrontmatter.sourcePath: "test/second-lesson.mdx",
  lesson: {
    ...first.GuideLessonFrontmatter.lesson,
    id,
    position,
    exercise: {...first.lesson.exercise, id: exerciseId},
  },
}

test("parses lessons without unused description and exercise title metadata", async () => {
  expect(completeLesson->parse)->toEqual(
    Ok({
      GuideLessonFrontmatter.sourcePath,
      lesson: {
        GuideLesson.id: "test-lesson",
        position: 1,
        missionLabel: "Test mission",
        title: "Test lesson",
        content: "Test body.",
        exercise: {id: "test-lesson/example", initialCode: "let answer = 42", expectedOutput: "42"},
      },
    }),
  )
})

test("rejects frontmatter without a lesson id", async () => {
  expect(completeLesson->String.replace("id: test-lesson\n", "")->parse)->toEqual(
    Error(`Guide lesson ${sourcePath} frontmatter "id" must be a non-empty string.`),
  )
})

[
  "Test-lesson",
  "test_lesson",
  "test/lesson",
  "test lesson",
  "tést",
  "-test",
  "test-",
  "test--lesson",
  "test\n",
]->Array.forEach(id =>
  test(`rejects unsafe lesson id ${JSON.String(id)->JSON.stringify}`, async () => {
    let raw =
      completeLesson->String.replace(
        "id: test-lesson\n",
        `id: ${JSON.String(id)->JSON.stringify}\n`,
      )
    expect(raw->parse)->toEqual(
      Error(
        `Guide lesson ${sourcePath} frontmatter "id" must be a URL-safe slug (lowercase ASCII letters and digits, with hyphens between words).`,
      ),
    )
  })
)

[
  "test-lesson/Example",
  "/test-lesson/example",
  "test-lesson/",
  "test-lesson//example",
  "test-lesson/../example",
]->Array.forEach(id =>
  test(`rejects unsafe exercise id ${id}`, async () => {
    let raw = completeLesson->String.replace("id: test-lesson/example", `id: ${id}`)
    expect(raw->parse)->toEqual(
      Error(
        `Guide lesson ${sourcePath} frontmatter "exercise.id" must be one or more URL-safe slugs separated by slashes (lowercase ASCII letters and digits, with hyphens between words).`,
      ),
    )
  })
)

test("accepts slug ids with digits and slash-delimited exercise ids", async () => {
  let parsed =
    completeLesson
    ->String.replace("id: test-lesson\n", "id: lesson-2\n")
    ->String.replace("id: test-lesson/example", "id: lesson-2/part-1/example")
    ->parse
    ->Result.getOrThrow
  expect(parsed.lesson.id)->toBe("lesson-2")
  expect(parsed.lesson.exercise.id)->toBe("lesson-2/part-1/example")
})

[
  "1.5",
  "-0.5",
  "\"2\"",
  "true",
  "null",
  ".inf",
  ".nan",
  "2147483648",
  "-2147483649",
  "9007199254740991",
]->Array.forEach(position =>
  test(`rejects non-integer or out-of-range lesson position ${position}`, async () => {
    let raw = completeLesson->String.replace("position: 1", `position: ${position}`)
    expect(raw->parse)->toEqual(
      Error(`Guide lesson ${sourcePath} frontmatter "position" must be a 32-bit integer.`),
    )
  })
)

["-2147483648", "0", "2", "2147483647"]->Array.forEach(position =>
  test(`preserves integer lesson position ${position}`, async () => {
    let parsed =
      completeLesson
      ->String.replace("position: 1", `position: ${position}`)
      ->parse
      ->Result.getOrThrow
    expect(parsed.lesson.position)->toBe(position->Int.fromString->Option.getOrThrow)
  })
)

[
  "",
  "  expectedOuput: \"42\"\n",
  "  expectedOutput: 42\n",
  "  expectedOutput: true\n",
  "  expectedOutput: null\n",
]->Array.forEach(replacement =>
  test(
    `rejects missing, misspelled, or non-string expectedOutput ${JSON.String(
        replacement,
      )->JSON.stringify}`,
    async () => {
      let raw = completeLesson->String.replace("  expectedOutput: \"42\"\n", replacement)
      expect(raw->parse)->toEqual(
        Error(`Guide lesson ${sourcePath} frontmatter "exercise.expectedOutput" must be a string.`),
      )
    },
  )
)

["", "  ", "42"]->Array.forEach(output =>
  test(`preserves exact expected output ${JSON.String(output)->JSON.stringify}`, async () => {
    let parsed =
      completeLesson
      ->String.replace(
        "expectedOutput: \"42\"",
        `expectedOutput: ${JSON.String(output)->JSON.stringify}`,
      )
      ->parse
      ->Result.getOrThrow
    expect(parsed.lesson.exercise.expectedOutput)->toBe(output)
  })
)

test("collects parsed guide lessons", async () => {
  let first = completeLessonResult()
  let second = first->secondLesson
  expect(GuideLessonContent.collect([Ok(first), Ok(second)]))->toEqual(Ok([first, second]))
})

test("preserves the first frontmatter error while collecting lessons", async () => {
  expect(
    GuideLessonContent.collect([
      Ok(completeLessonResult()),
      Error("first error"),
      Error("second error"),
    ]),
  )->toEqual(Error("first error"))
})

test("sorts validated lessons without exposing their source paths", async () => {
  let first = completeLessonResult()
  let second = first->secondLesson
  expect(GuideLessonContent.validateAndSort([second, first]))->toEqual(
    Ok([first.lesson, second.lesson]),
  )
})

test("accepts distinct guide identifiers and positions", async () => {
  let first = completeLessonResult()
  expect(GuideLessonFrontmatter.validate([first, first->secondLesson]))->toEqual(Ok())
})

test("rejects duplicate guide lesson ids", async () => {
  let first = completeLessonResult()
  expect(
    GuideLessonFrontmatter.validate([first, first->secondLesson(~id=first.lesson.id)]),
  )->toEqual(
    Error(
      GuideLessonFrontmatter.DuplicateLessonId({
        value: "test-lesson",
        sourcePaths: ["test/lesson.mdx", "test/second-lesson.mdx"],
      }),
    ),
  )
})

test("rejects duplicate guide exercise ids", async () => {
  let first = completeLessonResult()
  expect(
    GuideLessonFrontmatter.validate([
      first,
      first->secondLesson(~exerciseId=first.lesson.exercise.id),
    ]),
  )->toEqual(
    Error(
      GuideLessonFrontmatter.DuplicateExerciseId({
        value: "test-lesson/example",
        sourcePaths: ["test/lesson.mdx", "test/second-lesson.mdx"],
      }),
    ),
  )
})

test("rejects duplicate guide lesson positions", async () => {
  let first = completeLessonResult()
  expect(
    GuideLessonFrontmatter.validate([first, first->secondLesson(~position=first.lesson.position)]),
  )->toEqual(
    Error(
      GuideLessonFrontmatter.DuplicatePosition({
        value: "1",
        sourcePaths: ["test/lesson.mdx", "test/second-lesson.mdx"],
      }),
    ),
  )
})
