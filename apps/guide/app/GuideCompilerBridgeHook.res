let useCompilerBridge = (
  ~bundleBaseUrl,
  ~versions,
  ~code,
  ~editorRef: React.ref<option<CodeMirror.editorInstance>>,
  ~setOutput,
) => {
  let compilerVersions = React.useMemo(
    () => GuideCompilerSettings.supportedVersions(versions),
    [versions],
  )
  let initialVersion = React.useMemo(
    () => compilerVersions->GuideCompilerSettings.latestStableParsedVersion,
    [compilerVersions],
  )

  let (compilerState, compilerDispatch) = CompilerManagerHook.useCompilerManager(
    ~bundleBaseUrl,
    ~initialVersion?,
    ~initialModuleSystem=GuideCompilerSettings.moduleSystem,
    ~initialWarnFlags=GuideCompilerSettings.warnFlags,
    ~syncUrl=false,
    ~versions=compilerVersions,
  )

  let lastCompiledCode = React.useRef("")
  let lastExecutedJsCode = React.useRef("")
  let isWaitingForRuntimeOutput = React.useRef(false)

  React.useEffect(() => {
    switch compilerState {
    | Ready({targetLang}) if code !== lastCompiledCode.current =>
      let timer = setTimeout(~handler=() => {
        lastCompiledCode.current = code
        compilerDispatch(CompileCode(targetLang, code))
      }, ~timeout=150)
      Some(() => clearTimeout(timer))
    | _ => None
    }
  }, (code, compilerState, compilerDispatch))

  React.useEffect(() => {
    let cb = event => {
      let data = event["data"]
      let appendLog = (level, content) => {
        let runtimeLog = {GuideCompilerFeedback.Output.level, content}
        if isWaitingForRuntimeOutput.current {
          isWaitingForRuntimeOutput.current = false
          setOutput(_ => runtimeLog->GuideCompilerFeedback.Output.fromRuntimeLog)
        } else {
          setOutput(output => output->GuideCompilerFeedback.Output.withRuntimeLog(runtimeLog))
        }
      }

      switch data["type"] {
      | #log => appendLog(#log, data["args"])
      | #warn => appendLog(#warn, data["args"])
      | #error => appendLog(#error, data["args"])
      | _ => ()
      }
    }
    WebAPI.Window.addEventListener(window, Custom("message"), cb)
    Some(() => WebAPI.Window.removeEventListener(window, Custom("message"), cb))
  }, [setOutput])

  React.useEffect(() => {
    let feedback = compilerState->GuideCompilerFeedback.editorFeedbackFromState
    editorRef.current->Option.forEach(editor => {
      CodeMirror.editorSetErrors(editor, feedback.errors)
      CodeMirror.editorSetHoverHints(editor, feedback.hoverHints)
    })
    switch compilerState->GuideCompilerFeedback.outputUpdateFromState {
    | Some(output) =>
      isWaitingForRuntimeOutput.current = false
      setOutput(_ => output)
    | None => ()
    }
    None
  }, (compilerState, setOutput))

  React.useEffect(() => {
    switch compilerState {
    | Ready({selected, result: Comp(Success({jsCode, typeHints}))})
      if jsCode !== lastExecutedJsCode.current =>
      lastExecutedJsCode.current = jsCode
      let runtimeJsCode = switch GuideRuntimeSource.instrument(~code, ~typeHints) {
      | Some(runtimeCode) =>
        // The instrumented source may fail on compiler internals; fall back to user JS in that case.
        switch selected.instance->RescriptCompilerApi.Compiler.resCompile(runtimeCode) {
        | Success({jsCode}) => jsCode
        | Fail(_) | UnexpectedError(_) | Unknown(_, _) => jsCode
        }
      | None => jsCode
      }

      switch runtimeJsCode->GuideRuntimeTransform.transform(
        ~resultBindingName=GuideRuntimeSource.resultBindingName,
      ) {
      | Some({code: runtimeCode, imports}) =>
        isWaitingForRuntimeOutput.current = true
        let imports =
          imports->Dict.mapValues(path =>
            path->GuideRuntimeImport.url(~bundleBaseUrl, ~compilerVersion=selected.id)
          )
        let timer = setTimeout(
          ~handler=() => EvalIFrame.sendOutput(runtimeCode, imports),
          ~timeout=50,
        )
        Some(
          () => {
            isWaitingForRuntimeOutput.current = false
            clearTimeout(timer)
          },
        )
      | None => None
      }
    | Compiling(_) =>
      lastExecutedJsCode.current = ""
      None
    | _ => None
    }
  }, (compilerState, bundleBaseUrl))
}
