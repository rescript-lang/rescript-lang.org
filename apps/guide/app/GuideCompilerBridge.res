@react.component
let make = (
  ~bundleBaseUrl,
  ~versions: array<string>,
  ~code,
  ~editorRef: React.ref<option<CodeMirror.editorInstance>>,
  ~setOutput,
) => {
  GuideCompilerBridgeHook.useCompilerBridge(
    ~bundleBaseUrl,
    ~versions,
    ~code,
    ~editorRef,
    ~setOutput,
  )

  <div className="guide-runtime-frame">
    <EvalIFrame />
  </div>
}
