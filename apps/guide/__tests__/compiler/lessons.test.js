import { beforeAll, afterEach, expect, test, vi } from "vitest";
import { loadCompiler, runProgram } from "../../scripts/lesson-compiler.mjs";
import * as Settings from "../../app/GuideCompilerSettings.jsx";
import * as Validation from "../../app/GuideLessonValidation.jsx";
import * as Content from "../../app/GuideLessonContent.jsx";

const bundleBaseUrl = "https://cdn.rescript-lang.org";
let compiler;
beforeAll(async () => {
  compiler = await loadCompiler(
    bundleBaseUrl,
    Settings.version,
    Settings.moduleSystem,
    Settings.warnFlags,
  );
}, 60000);
afterEach(() => vi.unstubAllGlobals());

function exercise(overrides = {}) {
  return {
    sourcePath: "test-lesson.mdx",
    initialCode: 'let greeting = "hello"',
    solutionCode: 'let greeting = "hello"',
    expectedOutput: "hello",
    ...overrides,
  };
}

test("the pinned browser compiler validates every real lesson", async () => {
  expect(compiler.version).toBe(Settings.version.slice(1));
  await expect(Validation.validate(bundleBaseUrl)).resolves.toBeUndefined();
  const published = JSON.stringify(Content.load());
  expect(published).not.toContain("solutionCode");
  expect(published).not.toContain('greet(\\"Spock\\")');
});

test("invalid starter code fails even when its reference solution is valid", async () => {
  await expect(
    Validation.validateExercise(
      compiler,
      bundleBaseUrl,
      exercise({ initialCode: "let x =" }),
    ),
  ).rejects.toThrow(/test-lesson\.mdx exercise\.initialCode does not compile/);
});

test("invalid reference solutions identify the file and field", async () => {
  await expect(
    Validation.validateExercise(
      compiler,
      bundleBaseUrl,
      exercise({ solutionCode: "let x: int = false" }),
    ),
  ).rejects.toThrow(/test-lesson\.mdx exercise\.solutionCode does not compile/);
});

test("output mismatches fail with the expected and actual strings", async () => {
  await expect(
    Validation.validateExercise(
      compiler,
      bundleBaseUrl,
      exercise({ expectedOutput: "hello " }),
    ),
  ).rejects.toThrow(
    'exercise.expectedOutput "hello " did not match solution output "hello"',
  );
});

test("runtime failures identify the reference solution", async () => {
  await expect(
    Validation.validateExercise(
      compiler,
      bundleBaseUrl,
      exercise({ solutionCode: 'JsError.throwWithMessage("boom")' }),
    ),
  ).rejects.toThrow(
    /test-lesson\.mdx exercise\.solutionCode failed at runtime: boom/,
  );
});

test("solutions execute against the pinned compiler's published runtime imports", async () => {
  await expect(
    Validation.validateExercise(
      compiler,
      bundleBaseUrl,
      exercise({
        solutionCode: "let values = [1, 2]->Array.map(value => value + 1)",
        expectedOutput: "[2,3]",
      }),
    ),
  ).resolves.toBeUndefined();
});

test("final expressions use the browser's source instrumentation", async () => {
  await expect(
    Validation.validateExercise(
      compiler,
      bundleBaseUrl,
      exercise({
        solutionCode: 'let greeting = "starter"\nInt.toString(42)',
        expectedOutput: "42",
      }),
    ),
  ).resolves.toBeUndefined();
});

test("multiple console arguments match the browser checkpoint serialization", async () => {
  await expect(
    Validation.validateExercise(
      compiler,
      bundleBaseUrl,
      exercise({
        solutionCode: 'Console.log2("answer", 42)',
        expectedOutput: "answer 42",
      }),
    ),
  ).resolves.toBeUndefined();
});

test("runaway solutions stop with a timeout", async () => {
  await expect(
    runProgram({ code: "while (true) {}", imports: {} }),
  ).rejects.toThrow(/timed out/);
});

test("missing compiler assets fail with the URL and HTTP status", async () => {
  vi.stubGlobal(
    "fetch",
    vi.fn(async () => new Response("missing", { status: 404 })),
  );
  await expect(
    loadCompiler(
      "https://missing-guide.test",
      Settings.version,
      Settings.moduleSystem,
      Settings.warnFlags,
    ),
  ).rejects.toThrow(
    `https://missing-guide.test/${Settings.version}/compiler.js: HTTP 404`,
  );
});

test("a bundle claiming a different compiler version is rejected", async () => {
  vi.stubGlobal(
    "fetch",
    vi.fn(
      async (url) =>
        new Response(
          url.endsWith("/compiler.js")
            ? 'globalThis.rescript_compiler = {make: () => ({version: "13.0.0"})};'
            : "",
        ),
    ),
  );
  await expect(
    loadCompiler(
      "https://wrong-guide.test",
      Settings.version,
      Settings.moduleSystem,
      Settings.warnFlags,
    ),
  ).rejects.toThrow(
    `Expected guide compiler ${Settings.version}, received 13.0.0`,
  );
});

test.each([undefined, 42, false])(
  "reference validation rejects missing or non-string expected output: %s",
  (expectedOutput) => {
    const raw = `---\nexercise:\n  initialCode: let x = 1\n${expectedOutput === undefined ? "" : `  expectedOutput: ${expectedOutput}\n`}---\n`;
    expect(() => Validation.fromRaw(raw, "broken.mdx")).toThrow(
      "broken.mdx exercise.expectedOutput must be a string",
    );
  },
);

test("reference code defaults to the starter and preserves an empty expected output", () => {
  const parsed = Validation.fromRaw(
    '---\nexercise:\n  initialCode: let x = ""\n  expectedOutput: ""\n---\n',
    "empty.mdx",
  );
  expect(parsed.solutionCode).toBe(parsed.initialCode);
  expect(parsed.expectedOutput).toBe("");
});

test("empty reference code is an authoring error", () => {
  expect(() =>
    Validation.fromRaw(
      '---\nexercise:\n  initialCode: let x = 1\n  expectedOutput: "1"\n  solutionCode: ""\n---\n',
      "empty.mdx",
    ),
  ).toThrow("empty.mdx exercise.solutionCode must be a non-empty string");
});
