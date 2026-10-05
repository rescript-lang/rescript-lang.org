open Vitest

test("rewrites the compiled final expression into a console log", async () => {
  let result = GuideRuntimeTransform.transform(`let value = 52;
value;

export {
  value,
};`)

  let {code, imports} = result->Option.getOrThrow

  expect(code->String.includes("console.log(value)"))->toBe(true)
  expect(code->String.includes("export"))->toBe(false)
  expect(imports->Dict.keysToArray->Array.length)->toBe(0)
})

test("rewrites the guide runtime result binding into a console log", async () => {
  let result = GuideRuntimeTransform.transform(
    ~resultBindingName=GuideRuntimeSource.resultBindingName,
    `let __rescriptGuideOutput = 52;

export {
  __rescriptGuideOutput,
};`,
  )

  let {code} = result->Option.getOrThrow
  expect(code->String.includes("console.log(__rescriptGuideOutput)"))->toBe(true)
})

test("rewrites the last compiled binding into a console log", async () => {
  let result = GuideRuntimeTransform.transform(`let greeting = "hello, world!";

export {
  greeting,
};`)

  let {code} = result->Option.getOrThrow
  expect(code->String.includes("console.log(greeting)"))->toBe(true)
})

test("skips runtime execution when compiled code has no expression or binding", async () => {
  let result = GuideRuntimeTransform.transform(`export {};`)

  expect(result->Option.isNone)->toBe(true)
})

test("instruments the compiler-reported final expression range", async () => {
  let code = `let greeting = "hello, world!"

greeting`
  let typeHints = [
    RescriptCompilerApi.TypeHint.Binding({
      start: {line: 1, col: 0},
      end: {line: 1, col: 30},
      hint: "string",
    }),
    RescriptCompilerApi.TypeHint.Expression({
      start: {line: 3, col: 0},
      end: {line: 3, col: 8},
      hint: "string",
    }),
  ]

  let instrumentedCode = GuideRuntimeSource.instrument(~code, ~typeHints)->Option.getOrThrow

  expect(instrumentedCode->String.includes("let __rescriptGuideOutput = (greeting)"))->toBe(true)
})

test("prefers the outermost latest expression range", async () => {
  let code = `let add = (a, b) => a + b

add(10, 42)`
  let typeHints = [
    RescriptCompilerApi.TypeHint.Expression({
      start: {line: 3, col: 8},
      end: {line: 3, col: 10},
      hint: "int",
    }),
    RescriptCompilerApi.TypeHint.Expression({
      start: {line: 3, col: 0},
      end: {line: 3, col: 11},
      hint: "int",
    }),
    RescriptCompilerApi.TypeHint.Binding({
      start: {line: 1, col: 0},
      end: {line: 1, col: 25},
      hint: "(int, int) => int",
    }),
  ]

  let instrumentedCode = GuideRuntimeSource.instrument(~code, ~typeHints)->Option.getOrThrow

  expect(instrumentedCode->String.includes("let __rescriptGuideOutput = (add(10, 42))"))->toBe(true)
})

test("does not instrument expressions nested inside a binding", async () => {
  let code = `let value = 52`
  let typeHints = [
    RescriptCompilerApi.TypeHint.Expression({
      start: {line: 1, col: 12},
      end: {line: 1, col: 14},
      hint: "int",
    }),
  ]

  expect(GuideRuntimeSource.instrument(~code, ~typeHints)->Option.isNone)->toBe(true)
})

test("normalizes old compiler runtime import filenames", async () => {
  let alpha7 = Semver.parse("v12.0.0-alpha.7")->Option.getOrThrow
  let oldV11 = Semver.parse("v11.1.4")->Option.getOrThrow
  let stableV12 = Semver.parse("v12.0.0")->Option.getOrThrow

  expect(
    GuideRuntimeImport.filenameForCompiler(~compilerVersion=alpha7, "./stdlib/core__array"),
  )->toBe("Array")
  expect(
    GuideRuntimeImport.filenameForCompiler(~compilerVersion=oldV11, "./stdlib/core__array"),
  )->toBe("Core__array")
  expect(
    GuideRuntimeImport.filenameForCompiler(~compilerVersion=stableV12, "./stdlib/core__array"),
  )->toBe("core__array")
})

test("resolves v13 exception imports to the published runtime file", async () => {
  let compilerVersion = Semver.parse("v13.0.0-alpha.6")->Option.getOrThrow
  let url = GuideRuntimeImport.url(
    ~bundleBaseUrl="https://cdn.rescript-lang.org",
    ~compilerVersion,
    "./stdlib/Primitive_exceptions.mjs",
  )

  expect(url)->toBe(
    "https://cdn.rescript-lang.org/v13.0.0-alpha.6/compiler-builtins/stdlib/Primitive_exceptions.js",
  )
})

test("preserves runtime imports that already use the published extension", async () => {
  let compilerVersion = Semver.parse("v12.3.1")->Option.getOrThrow
  let url = GuideRuntimeImport.url(
    ~bundleBaseUrl="https://cdn.rescript-lang.org",
    ~compilerVersion,
    "./stdlib/Stdlib_Array.js",
  )

  expect(url)->toBe(
    "https://cdn.rescript-lang.org/v12.3.1/compiler-builtins/stdlib/Stdlib_Array.js",
  )
})

test("normalizes old compiler versions for runtime imports", async () => {
  let alpha7 = Semver.parse("v12.0.0-alpha.7")->Option.getOrThrow
  let alpha9 = Semver.parse("v12.0.0-alpha.9")->Option.getOrThrow
  let oldV11 = Semver.parse("v11.1.4")->Option.getOrThrow

  expect(GuideRuntimeImport.compilerVersionForRuntimeImport(alpha7)->Semver.toString)->toBe(
    "v12.0.0-alpha.9",
  )
  expect(GuideRuntimeImport.compilerVersionForRuntimeImport(alpha9)->Semver.toString)->toBe(
    "v12.0.0-alpha.9",
  )
  expect(GuideRuntimeImport.compilerVersionForRuntimeImport(oldV11)->Semver.toString)->toBe(
    "v11.2.0-beta.2",
  )
})
