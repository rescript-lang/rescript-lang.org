@react.component
let make = (
  ~bundleBaseUrl,
  ~code,
  ~editorRef: React.ref<option<CodeMirror.editorInstance>>,
  ~setOutput,
) => {
  GuideCompilerBridgeHook.useCompilerBridge(~bundleBaseUrl, ~code, ~editorRef, ~setOutput)

  <div className="guide-runtime-frame">
    <EvalIFrame />
  </div>
}
