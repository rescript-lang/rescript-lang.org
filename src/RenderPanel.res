let wrapReactApp = code =>
  `(function () {
  ${code}
  window.reactRoot.render(React.createElement(App.make, {}));
})();`

@react.component
let make = (~compilerState: CompilerManagerHook.state, ~clearLogs, ~runOutput) => {
  let (validReact, setValidReact) = React.useState(() => false)
  React.useEffect(() => {
    if runOutput {
      switch compilerState {
      | CompilerManagerHook.Ready({selected, result: Comp(Success({js_code}))}) =>
        clearLogs()
        open Babel

        let ast = Parser.parse(js_code, {sourceType: "module"})
        let {entryPointExists, code, imports} = PlaygroundValidator.validate(ast)
        let imports = imports->Dict.mapValues(path => {
          let filename = path->String.sliceToEnd(~start=9) // the part after "./stdlib/"
          CompilerManagerHook.CdnMeta.getStdlibRuntimeUrl(selected.id, filename)
        })

        entryPointExists
          ? code->wrapReactApp->EvalIFrame.sendOutput(imports)
          : EvalIFrame.sendOutput(code, imports)
        setValidReact(_ => entryPointExists)
      | _ => ()
      }
    }
    None
  }, (compilerState, runOutput))

  <div className={`px-2 relative ${validReact ? "flex-1 py-2 overflow-y-auto" : "h-auto py-6"}`}>
    <h2 className="font-bold text-gray-5/50 absolute right-2 top-2"> {React.string("React")} </h2>
    {validReact
      ? React.null
      : React.string(
          "Create a React component called 'App' if you want to render it here, then enable 'Auto-run'.",
        )}
    <div className={validReact ? "h-full" : "h-0"}>
      <EvalIFrame />
    </div>
  </div>
}
