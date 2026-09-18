type t = {
  code: string,
  containerRef: React.ref<Nullable.t<Dom.element>>,
  editorRef: React.ref<option<CodeMirror.editorInstance>>,
  reset: ReactEvent.Mouse.t => unit,
}

let useEditor = (~exercise: GuideLesson.exercise, ~theme): t => {
  let containerRef: React.ref<Nullable.t<Dom.element>> = React.useRef(Nullable.null)
  let editorRef: React.ref<option<CodeMirror.editorInstance>> = React.useRef(None)
  let isRestoringInitialCode = React.useRef(false)
  let (code, setCode) = React.useState(() => exercise.initialCode)

  React.useEffect(() => {
    editorRef.current->Option.forEach(editor =>
      CodeMirror.editorSetTheme(editor, theme->GuideLayout.themeToCodeMirror)
    )
    None
  }, [theme])

  React.useEffect(() => {
    switch containerRef.current {
    | Value(parent) =>
      let initialCode =
        GuideLayout.loadExerciseCode(exercise.id)->Option.getOr(exercise.initialCode)
      setCode(_ => initialCode)

      // Recreate CodeMirror on lesson changes so persisted drafts replace the editor doc and history.
      let config: CodeMirror.editorConfig = {
        parent: parent->GuideDom.toWebElement,
        initialValue: initialCode,
        mode: "rescript",
        readOnly: false,
        lineNumbers: true,
        lineWrapping: false,
        theme: theme->GuideLayout.themeToCodeMirror,
        keyMap: CodeMirror.KeyMap.Default,
        onChange: value => {
          if !isRestoringInitialCode.current {
            GuideLayout.saveExerciseCode(~exerciseId=exercise.id, ~code=value)
          }
          setCode(_ => value)
        },
        errors: [],
        hoverHints: [],
        minHeight: "100%",
      }
      let editor = CodeMirror.createEditor(config)
      editorRef.current = Some(editor)
      Some(
        () => {
          editorRef.current = None
          CodeMirror.editorDestroy(editor)
        },
      )
    | Null | Undefined => None
    }
  }, (exercise.id, exercise.initialCode))

  let reset = _event => {
    GuideLayout.clearExerciseCode(exercise.id)
    isRestoringInitialCode.current = true
    editorRef.current->Option.forEach(editor =>
      CodeMirror.editorSetValue(editor, exercise.initialCode)
    )
    isRestoringInitialCode.current = false
    setCode(_ => exercise.initialCode)
  }

  {code, containerRef, editorRef, reset}
}
