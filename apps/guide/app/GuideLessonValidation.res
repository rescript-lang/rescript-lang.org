// Build-only authoring data: solutions and expected diagnostics never enter loader data.
type exercise = {
  sourcePath: string,
  initialCode: string,
  solutionCode: string,
  expectedOutput: string,
  expectedInitialDiagnostic: option<string>,
}

@module("../scripts/lesson-compiler.mjs")
external loadCompiler: (
  ~bundleBaseUrl: string,
  ~version: string,
  ~moduleSystem: string,
  ~warnFlags: string,
) => promise<RescriptCompilerApi.Compiler.t> = "loadCompiler"

@module("../scripts/lesson-compiler.mjs")
external runProgram: GuideRuntimeTransform.t => promise<
  array<GuideCompilerFeedback.Output.runtimeLog>,
> = "runProgram"

let fail = message => JsError.throwWithMessage(message)

let readString = (~dict, ~sourcePath, ~key, ~allowEmpty=false) =>
  switch dict->Dict.get(key) {
  | Some(JSON.String(value)) if allowEmpty || value->String.trim !== "" => value
  | _ =>
    fail(
      `Guide lesson ${sourcePath} exercise.${key} must be ${allowEmpty
          ? "a string"
          : "a non-empty string"}.`,
    )
  }

let fromRaw = (~raw, ~sourcePath) => {
  let {frontmatter}: MarkdownParser.result = MarkdownParser.parseSync(raw)
  let dict =
    frontmatter
    ->JSON.Decode.object
    ->Option.flatMap(dict => dict->Dict.get("exercise"))
    ->Option.flatMap(JSON.Decode.object)
  switch dict {
  | None => fail(`Guide lesson ${sourcePath} must have exercise frontmatter.`)
  | Some(dict) =>
    let initialCode = readString(~dict, ~sourcePath, ~key="initialCode")
    let expectedInitialDiagnostic = switch dict->Dict.get("expectedInitialDiagnostic") {
    | None => None
    | Some(_) => Some(readString(~dict, ~sourcePath, ~key="expectedInitialDiagnostic"))
    }
    let solutionCode = switch dict->Dict.get("solutionCode") {
    | None =>
      switch expectedInitialDiagnostic {
      | None => initialCode
      | Some(_) =>
        fail(
          `Guide lesson ${sourcePath} exercise.solutionCode is required when exercise.expectedInitialDiagnostic is set.`,
        )
      }
    | Some(_) => readString(~dict, ~sourcePath, ~key="solutionCode")
    }
    {
      sourcePath,
      initialCode,
      solutionCode,
      expectedOutput: readString(~dict, ~sourcePath, ~key="expectedOutput", ~allowEmpty=true),
      expectedInitialDiagnostic,
    }
  }
}

let compile = (~compiler, ~sourcePath, ~field, code) =>
  switch compiler->RescriptCompilerApi.Compiler.resCompile(code) {
  | Success(result) => result
  | Fail(failure) =>
    let details = failure->GuideCompilerFeedback.compileFailToOutputLines->Array.join("\n")
    fail(
      `Guide lesson ${sourcePath} exercise.${field} does not compile with ${GuideCompilerSettings.version}:\n${details}`,
    )
  | UnexpectedError(message) | Unknown(message, _) =>
    fail(`Guide lesson ${sourcePath} exercise.${field}: ${message}`)
  }

let validateInitialDiagnostic = (~sourcePath, ~expected, result) => {
  let expectation = `Guide lesson ${sourcePath} exercise.initialCode expected a syntax or type diagnostic containing ${expected
    ->JSON.Encode.string
    ->JSON.stringify}`
  switch result {
  | RescriptCompilerApi.CompilationResult.Fail(SyntaxErr(messages) | TypecheckErr(messages)) =>
    let actual = messages->Array.map(message => message.shortMsg->GuideCompilerFeedback.plainText)
    if (
      actual->Array.length === 0 ||
        !(actual->Array.every(message => message->String.includes(expected)))
    ) {
      fail(`${expectation}, but received:\n${actual->Array.join("\n")}`)
    }
  | Fail(failure) =>
    let details = failure->GuideCompilerFeedback.compileFailToOutputLines->Array.join("\n")
    fail(`${expectation}, but received a different compiler failure:\n${details}`)
  | Success(_) => fail(`${expectation}, but compiled successfully.`)
  | UnexpectedError(message) | Unknown(message, _) =>
    fail(`${expectation}, but the compiler failed unexpectedly: ${message}`)
  }
}

let validateExercise = async (~compiler, ~bundleBaseUrl, exercise) => {
  let {sourcePath, initialCode, solutionCode, expectedOutput, expectedInitialDiagnostic} = exercise
  switch expectedInitialDiagnostic {
  | None => compile(~compiler, ~sourcePath, ~field="initialCode", initialCode)->ignore
  | Some(expected) =>
    validateInitialDiagnostic(
      ~sourcePath,
      ~expected,
      compiler->RescriptCompilerApi.Compiler.resCompile(initialCode),
    )
  }
  let {jsCode, typeHints} = compile(~compiler, ~sourcePath, ~field="solutionCode", solutionCode)
  let program = switch GuideRuntimeProgram.fromCompilation(
    ~compiler,
    ~code=solutionCode,
    ~jsCode,
    ~typeHints,
  ) {
  | Some(program) => {
      ...program,
      imports: program.imports->Dict.mapValues(path =>
        GuideRuntimeImport.url(
          ~bundleBaseUrl,
          ~compilerVersion=GuideCompilerSettings.parsedVersion,
          path,
        )
      ),
    }
  | None => fail(`Guide lesson ${sourcePath} exercise.solutionCode has no executable output.`)
  }

  let logs = try {
    await runProgram(program)
  } catch {
  | JsExn(error) =>
    fail(
      `Guide lesson ${sourcePath} exercise.solutionCode failed at runtime: ${error
        ->JsExn.message
        ->Option.getOr("Unknown runtime error")}`,
    )
  }
  if !(logs->Array.some(log => GuideLesson.runtimeLogText(log) === expectedOutput)) {
    let actual = logs->Array.map(GuideLesson.runtimeLogText)->Array.join("\n")
    fail(
      `Guide lesson ${sourcePath} exercise.expectedOutput ${expectedOutput
        ->JSON.Encode.string
        ->JSON.stringify} did not match solution output ${actual
        ->JSON.Encode.string
        ->JSON.stringify}.`,
    )
  }
}

let validate = async (~bundleBaseUrl, ~dir=GuideLessonContent.lessonsDir()) => {
  let exercises = GuideLessonContent.scanDir(dir)->Array.map(sourcePath => {
    let raw = Node.Fs.readFileSync2(sourcePath, "utf8")
    fromRaw(~raw, ~sourcePath)
  })
  let compiler = await loadCompiler(
    ~bundleBaseUrl,
    ~version=GuideCompilerSettings.version,
    ~moduleSystem=GuideCompilerSettings.moduleSystem,
    ~warnFlags=GuideCompilerSettings.warnFlags,
  )
  // The browser compiler is stateful; compile lessons sequentially.
  for index in 0 to exercises->Array.length - 1 {
    await validateExercise(~compiler, ~bundleBaseUrl, exercises->Array.getUnsafe(index))
  }
}
