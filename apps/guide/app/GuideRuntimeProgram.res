// Keep lesson validation and browser execution on the same transformation path.
let fromCompilation = (~compiler, ~code, ~jsCode, ~typeHints) => {
  let runtimeJsCode = switch GuideRuntimeSource.instrument(~code, ~typeHints) {
  | Some(runtimeCode) =>
    switch compiler->RescriptCompilerApi.Compiler.resCompile(runtimeCode) {
    | Success({jsCode}) => jsCode
    | Fail(_) | UnexpectedError(_) | Unknown(_, _) => jsCode
    }
  | None => jsCode
  }

  runtimeJsCode->GuideRuntimeTransform.transform(
    ~resultBindingName=GuideRuntimeSource.resultBindingName,
  )
}
