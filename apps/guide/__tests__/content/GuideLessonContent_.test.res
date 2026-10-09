open Vitest

@module("vitest") external afterEach: (unit => unit) => unit = "afterEach"
@module("node:os") external tmpdir: unit => string = "tmpdir"
@module("node:fs") external mkdtempSync: string => string = "mkdtempSync"
@module("node:fs") external rmSync: (string, {"recursive": bool, "force": bool}) => unit = "rmSync"

let temporaryDir = ref(None)

afterEach(() => {
  temporaryDir.contents->Option.forEach(dir => rmSync(dir, {"recursive": true, "force": true}))
  temporaryDir.contents = None
})

let makeLessonsDir = () => {
  let dir = Node.Path.join2(tmpdir(), "rescript-guide-lessons-")->mkdtempSync
  temporaryDir.contents = Some(dir)
  dir
}

let writeLesson = (dir, filename, ~id, ~position, ~exerciseId) => {
  let raw = `---
position: ${position->Int.toString}
id: ${id}
missionLabel: Test mission
title: Test lesson
exercise:
  id: ${exerciseId}
  initialCode: let answer = 42
  expectedOutput: "42"
---

Test body.`
  Node.Fs.writeFileSync(Node.Path.join2(dir, filename), raw)
}

test("validates every published lesson and excludes build paths from loader data", async () => {
  let lessons = GuideLessonContent.load()->Result.getOrThrow
  expect(lessons->Array.length > 0)->toBe(true)
  expect(lessons)->toEqual(lessons->GuideLesson.sort)
  let serialized = lessons->JSON.stringifyAny->Option.getOrThrow
  expect(serialized->String.includes("\"sourcePath\":"))->toBe(false)
  expect(serialized->String.includes(Node.Process.cwd()))->toBe(false)
  expect(serialized->String.includes("\"description\":"))->toBe(false)
})

test("discovers nested MDX lessons, ignores other files, and sorts by position", async () => {
  let dir = makeLessonsDir()
  let nestedDir = Node.Path.join2(dir, "nested")
  Node.Fs.mkdirSync(nestedDir)
  writeLesson(dir, "a-later.mdx", ~id="later", ~position=10, ~exerciseId="later/example")
  writeLesson(nestedDir, "z-first.mdx", ~id="first", ~position=2, ~exerciseId="first/example")
  Node.Fs.writeFileSync(Node.Path.join2(dir, "notes.txt"), "not lesson frontmatter")

  let lessons = GuideLessonContent.load(~dir)->Result.getOrThrow
  expect(lessons->Array.map(lesson => lesson.GuideLesson.id))->toEqual(["first", "later"])
  expect(lessons->Array.map(lesson => lesson.GuideLesson.position))->toEqual([2, 10])
})

test("reports the source file and field when a lesson cannot be completed", async () => {
  let dir = makeLessonsDir()
  let file = Node.Path.join2(dir, "broken.mdx")
  writeLesson(dir, "broken.mdx", ~id="broken", ~position=1, ~exerciseId="broken/example")
  let raw = Node.Fs.readFileSync2(file, "utf8")->String.replace("expectedOutput:", "expectedOuput:")
  Node.Fs.writeFileSync(file, raw)

  expect(GuideLessonContent.load(~dir))->toEqual(
    Error(`Guide lesson ${file} frontmatter "exercise.expectedOutput" must be a string.`),
  )
})

[
  ("lesson id", "first", 2, "second/example"),
  ("exercise id", "second", 2, "first/example"),
  ("lesson position", "second", 1, "second/example"),
]->Array.forEach(((kind, id, position, exerciseId)) =>
  test(`reports both source files for a duplicate ${kind}`, async () => {
    let dir = makeLessonsDir()
    writeLesson(dir, "first.mdx", ~id="first", ~position=1, ~exerciseId="first/example")
    writeLesson(dir, "second.mdx", ~id, ~position, ~exerciseId)

    switch GuideLessonContent.load(~dir) {
    | Error(message) =>
      expect(message->String.startsWith(`Duplicate guide ${kind}`))->toBe(true)
      expect(message->String.includes(Node.Path.join2(dir, "first.mdx")))->toBe(true)
      expect(message->String.includes(Node.Path.join2(dir, "second.mdx")))->toBe(true)
    | Ok(_) => expect("accepted duplicate metadata")->toBe("validation error")
    }
  })
)
