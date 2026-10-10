let useCompilerBridge = (
  ~bundleBaseUrl,
  ~code,
  ~editorRef: React.ref<option<CodeMirror.editorInstance>>,
  ~setOutput,
) => {
  let compilerVersions = React.useMemo(() => [GuideCompilerSettings.parsedVersion], [])

  let (compilerState, compilerDispatch) = CompilerManagerHook.useCompilerManager(
    ~bundleBaseUrl,
    ~initialVersion=GuideCompilerSettings.parsedVersion,
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
    | Init =>
      let timer = setTimeout(
        ~handler=() =>
          setOutput(
            _ =>
              GuideCompilerFeedback.Output.make(
                ~status="Compiler setup failed",
                ~diagnostics=[
                  `ReScript ${GuideCompilerSettings.version} did not load within 15 seconds. Reload the page to try again.`,
                ],
              ),
          ),
        ~timeout=GuideCompilerSettings.loadingTimeoutMs,
      )
      Some(() => clearTimeout(timer))
    | _ => None
    }
  }, (compilerState, setOutput))

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

  let onLog = React.useCallback(runtimeLog => {
    if isWaitingForRuntimeOutput.current {
      isWaitingForRuntimeOutput.current = false
      setOutput(_ => runtimeLog->GuideCompilerFeedback.Output.fromRuntimeLog)
    } else {
      setOutput(output => output->GuideCompilerFeedback.Output.withRuntimeLog(runtimeLog))
    }
  }, [setOutput])
  RuntimeConsole.useLogs(onLog)

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
      switch GuideRuntimeProgram.fromCompilation(
        ~compiler=selected.instance,
        ~code,
        ~jsCode,
        ~typeHints,
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
