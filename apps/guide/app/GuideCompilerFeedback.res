module Api = RescriptCompilerApi

module Output = {
  type level = [
    | #log
    | #warn
    | #error
  ]
  type runtimeLog = {level: level, content: array<string>}

  type t = {
    status: string,
    diagnostics: array<string>,
    typeHints: array<string>,
    runtimeLogs: array<runtimeLog>,
  }

  let make = (~status, ~diagnostics=[], ~typeHints=[], ~runtimeLogs=[]) => {
    status,
    diagnostics,
    typeHints,
    runtimeLogs,
  }

  let initial = make(~status="Output", ~runtimeLogs=[{level: #log, content: ["hello, world!"]}])

  let withRuntimeLog = (output, runtimeLog) => {
    ...output,
    status: "Output",
    runtimeLogs: output.runtimeLogs->Array.concat([runtimeLog]),
  }

  let fromRuntimeLog = runtimeLog => make(~status="Output", ~runtimeLogs=[runtimeLog])
}

type editorFeedback = {
  errors: array<CodeMirror.Error.t>,
  hoverHints: array<CodeMirror.HoverHint.t>,
}

let emptyEditorFeedback = {errors: [], hoverHints: []}

let locMsgToEditorError = (~kind: CodeMirror.Error.kind, locMsg: Api.LocMsg.t) => {
  let {Api.LocMsg.row: row, column, endColumn, endRow, shortMsg} = locMsg
  {
    CodeMirror.Error.row,
    column,
    endColumn,
    endRow,
    text: shortMsg,
    kind,
  }
}

let warningToEditorError = (warning: Api.Warning.t) =>
  switch warning {
  | Warn({details}) | WarnErr({details}) => locMsgToEditorError(~kind=#Warning, details)
  }

let plainText = text => text->Ansi.parse->Ansi.Printer.plainString

let typeHintData = (typeHint: Api.TypeHint.t) =>
  switch typeHint {
  | TypeDeclaration(data) | Expression(data) | Binding(data) | CoreType(data) => data
  }

let typeHintsToHoverHints = typeHints =>
  typeHints->Array.map(typeHint => {
    let {Api.TypeHint.start: start, end, hint} = typeHint->typeHintData
    {
      CodeMirror.HoverHint.start: {
        line: start.line,
        col: start.col,
      },
      end: {
        line: end.line,
        col: end.col,
      },
      hint,
    }
  })

let compileFailToEditorErrors = (fail: Api.CompileFail.t) =>
  switch fail {
  | SyntaxErr(locMsgs) | TypecheckErr(locMsgs) | OtherErr(locMsgs) =>
    locMsgs->Array.map(locMsg => locMsgToEditorError(~kind=#Error, locMsg))
  | WarningErr(warnings) => warnings->Array.map(warningToEditorError)
  | WarningFlagErr({msg}) => [
      {
        CodeMirror.Error.row: 1,
        column: 0,
        endRow: 1,
        endColumn: 0,
        text: msg,
        kind: #Error,
      },
    ]
  }

let compileFailToOutputLines = (fail: Api.CompileFail.t) =>
  switch fail {
  | SyntaxErr(locMsgs) | TypecheckErr(locMsgs) | OtherErr(locMsgs) =>
    locMsgs->Array.map(locMsg => locMsg->Api.LocMsg.toCompactErrorLine(~prefix=#E)->plainText)
  | WarningErr(warnings) =>
    warnings->Array.map(warning => warning->Api.Warning.toCompactErrorLine->plainText)
  | WarningFlagErr({msg}) => [msg]
  }

let compilationResultToEditorFeedback = (result: Api.CompilationResult.t) =>
  switch result {
  | Success({warnings, typeHints}) => {
      errors: warnings->Array.map(warningToEditorError),
      hoverHints: typeHints->typeHintsToHoverHints,
    }
  | Fail(fail) => {
      errors: fail->compileFailToEditorErrors,
      hoverHints: [],
    }
  | UnexpectedError(_) | Unknown(_, _) => emptyEditorFeedback
  }

let compilationResultToOutputUpdate = (result: Api.CompilationResult.t) =>
  switch result {
  | Success(_) => None
  | Fail(fail) =>
    Some(Output.make(~status="Compiler error", ~diagnostics=fail->compileFailToOutputLines))
  | UnexpectedError(message) => Some(Output.make(~status="Compiler error", ~diagnostics=[message]))
  | Unknown(message, _) =>
    Some(Output.make(~status="Unknown compiler result", ~diagnostics=[message]))
  }

let editorFeedbackFromState = (state: CompilerManagerHook.state) =>
  switch state {
  | Ready({result: Comp(result)}) | Compiling({state: {result: Comp(result)}}) =>
    result->compilationResultToEditorFeedback
  | _ => emptyEditorFeedback
  }

let outputUpdateFromState = (state: CompilerManagerHook.state) =>
  switch state {
  | SetupFailed(message) =>
    Some(Output.make(~status="Compiler setup failed", ~diagnostics=[message]))
  | Ready({result: Comp(result)}) => result->compilationResultToOutputUpdate
  | Init
  | SwitchingCompiler(_, _)
  | Compiling(_)
  | Executing(_)
  | Ready({result: Nothing | Conv(_)}) =>
    None
  }
