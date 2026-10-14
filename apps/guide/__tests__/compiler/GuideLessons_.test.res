type assertion<'a>
@module("vitest") external test: (string, unit => promise<unit>) => unit = "test"
@module("vitest") @scope("test")
external for_: array<'a> => (string, 'a => promise<unit>) => unit = "for"
@module("vitest") external beforeAll: (unit => promise<unit>, int) => unit = "beforeAll"
@module("vitest") external afterEach: (unit => unit) => unit = "afterEach"
@module("vitest") external expect: 'a => assertion<'a> = "expect"
@send external toBe: (assertion<'a>, 'a) => unit = "toBe"
@send @scope("not") external notToContain: (assertion<string>, string) => unit = "toContain"
@send external toThrow: (assertion<unit => 'a>, string) => unit = "toThrow"
@send @scope("rejects")
external rejectsWith: (assertion<promise<'a>>, string) => promise<unit> = "toThrow"
@send @scope("resolves")
external resolvesToUnit: assertion<promise<unit>> => promise<unit> = "toBeUndefined"
@module("vitest") @scope("vi")
external stubFetch: (@as("fetch") _, string => promise<WebAPI.FetchAPI.response>) => unit =
  "stubGlobal"
@module("vitest") @scope("vi") external unstubGlobals: unit => unit = "unstubAllGlobals"

let bundleBaseUrl = "https://cdn.rescript-lang.org"
let compiler = ref(None)

beforeAll(async () => {
  compiler.contents = Some(
    await GuideLessonValidation.loadCompiler(
      ~bundleBaseUrl,
      ~version=GuideCompilerSettings.version,
      ~moduleSystem=GuideCompilerSettings.moduleSystem,
      ~warnFlags=GuideCompilerSettings.warnFlags,
    ),
  )
}, 60000)
afterEach(unstubGlobals)

let exercise = (
  ~initialCode=`let greeting = "hello"`,
  ~solutionCode=`let greeting = "hello"`,
  ~expectedOutput="hello",
  (),
): GuideLessonValidation.exercise => {
  sourcePath: "test-lesson.mdx",
  initialCode,
  solutionCode,
  expectedOutput,
}

let validateExercise = exercise =>
  GuideLessonValidation.validateExercise(
    ~compiler=compiler.contents->Option.getOrThrow,
    ~bundleBaseUrl,
    exercise,
  )

let loadCompiler = bundleBaseUrl =>
  GuideLessonValidation.loadCompiler(
    ~bundleBaseUrl,
    ~version=GuideCompilerSettings.version,
    ~moduleSystem=GuideCompilerSettings.moduleSystem,
    ~warnFlags=GuideCompilerSettings.warnFlags,
  )

test("the pinned browser compiler validates every real lesson", async () => {
  expect(compiler.contents->Option.getOrThrow->RescriptCompilerApi.Compiler.version)->toBe(
    GuideCompilerSettings.version->String.slice(~start=1),
  )
  await expect(GuideLessonValidation.validate(~bundleBaseUrl))->resolvesToUnit
  let published = GuideLessonContent.load()->JSON.stringifyAny->Option.getOrThrow
  expect(published)->notToContain("solutionCode")
  expect(published)->notToContain(`greet(\\"Spock\\")`)
})

test("invalid starter code fails even when its reference solution is valid", async () => {
  await expect(validateExercise(exercise(~initialCode="let x =", ())))->rejectsWith(
    "test-lesson.mdx exercise.initialCode does not compile",
  )
})

test("invalid reference solutions identify the file and field", async () => {
  await expect(validateExercise(exercise(~solutionCode="let x: int = false", ())))->rejectsWith(
    "test-lesson.mdx exercise.solutionCode does not compile",
  )
})

test("output mismatches fail with the expected and actual strings", async () => {
  await expect(
    validateExercise(exercise(~expectedOutput="hello ", ())),
  )->rejectsWith(`exercise.expectedOutput "hello " did not match solution output "hello"`)
})

test("runtime failures identify the reference solution", async () => {
  await expect(
    validateExercise(exercise(~solutionCode=`JsError.throwWithMessage("boom")`, ())),
  )->rejectsWith("test-lesson.mdx exercise.solutionCode failed at runtime: boom")
})

test("solutions execute against the pinned compiler's published runtime imports", async () => {
  await expect(
    validateExercise(
      exercise(
        ~solutionCode="let values = [1, 2]->Array.map(value => value + 1)",
        ~expectedOutput="[2,3]",
        (),
      ),
    ),
  )->resolvesToUnit
})

test("final expressions use the browser's source instrumentation", async () => {
  await expect(
    validateExercise(
      exercise(
        ~solutionCode=`let greeting = "starter"\nInt.toString(42)`,
        ~expectedOutput="42",
        (),
      ),
    ),
  )->resolvesToUnit
})

test("multiple console arguments match the browser checkpoint serialization", async () => {
  await expect(
    validateExercise(
      exercise(~solutionCode=`Console.log2("answer", 42)`, ~expectedOutput="answer 42", ()),
    ),
  )->resolvesToUnit
})

test("runaway solutions stop with a timeout", async () => {
  await expect(
    GuideLessonValidation.runProgram({code: "while (true) {}", imports: Dict.make()}),
  )->rejectsWith("timed out")
})

test("missing compiler assets fail with the URL and HTTP status", async () => {
  stubFetch(async _url => WebAPI.Response.fromString("missing", ~init={status: 404}))
  await expect(loadCompiler("https://missing-guide.test"))->rejectsWith(
    `https://missing-guide.test/${GuideCompilerSettings.version}/compiler.js: HTTP 404`,
  )
})

test("a bundle claiming a different compiler version is rejected", async () => {
  stubFetch(async url => {
    let code =
      url->String.endsWith("/compiler.js")
        ? `globalThis.rescript_compiler = {make: () => ({version: "13.0.0"})};`
        : ""
    WebAPI.Response.fromString(code)
  })
  await expect(loadCompiler("https://wrong-guide.test"))->rejectsWith(
    `Expected guide compiler ${GuideCompilerSettings.version}, received 13.0.0`,
  )
})

for_([
  None,
  Some(JSON.Number(42.0)),
  Some(JSON.Boolean(false)),
])(
  "reference validation rejects missing or non-string expected output: %s",
  async expectedOutput => {
    let field = switch expectedOutput {
    | None => ""
    | Some(value) => `  expectedOutput: ${value->JSON.stringify}\n`
    }
    let raw = `---\nexercise:\n  initialCode: let x = 1\n${field}---\n`
    expect(() => GuideLessonValidation.fromRaw(~raw, ~sourcePath="broken.mdx"))->toThrow(
      "broken.mdx exercise.expectedOutput must be a string",
    )
  },
)

test("reference code defaults to the starter and preserves an empty expected output", async () => {
  let parsed = GuideLessonValidation.fromRaw(
    ~raw=`---\nexercise:\n  initialCode: let x = ""\n  expectedOutput: ""\n---\n`,
    ~sourcePath="empty.mdx",
  )
  expect(parsed.solutionCode)->toBe(parsed.initialCode)
  expect(parsed.expectedOutput)->toBe("")
})

test("empty reference code is an authoring error", async () => {
  expect(() =>
    GuideLessonValidation.fromRaw(
      ~raw=`---\nexercise:\n  initialCode: let x = 1\n  expectedOutput: "1"\n  solutionCode: ""\n---\n`,
      ~sourcePath="empty.mdx",
    )
  )->toThrow("empty.mdx exercise.solutionCode must be a non-empty string")
})
