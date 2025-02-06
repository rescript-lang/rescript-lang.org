let wrapReactApp = code =>
  `(function () {
  ${code}
  window.reactRoot.render(React.createElement(App.make, {}));
})();`

let capitalizeFirstLetter = string => {
  let firstLetter = string->String.charAt(0)->String.toUpperCase
  `${firstLetter}${string->String.sliceToEnd(~start=1)}`
}

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
          let filename = switch selected.id {
          | {major: 12, minor: 0, patch: 0, preRelease: Some(Alpha(alpha))} if alpha < 8 =>
            let filename = if filename->String.startsWith("core__") {
              filename->String.sliceToEnd(~start=6)
            } else {
              filename
            }
            capitalizeFirstLetter(filename)
          | {major} if major < 12 && filename->String.startsWith("core__") =>
            capitalizeFirstLetter(filename)
          | _ => filename
          }
          let compilerVersion = switch selected.id {
          | {major: 12, minor: 0, patch: 0, preRelease: Some(Alpha(alpha))} if alpha < 8 => {
              Semver.major: 12,
              minor: 0,
              patch: 0,
              preRelease: Some(Alpha(8)),
            }
          | {major, minor} if (major === 11 && minor < 2) || major < 11 => {
              major: 11,
              minor: 2,
              patch: 0,
              preRelease: Some(Beta(1)),
            }
          | version => version
          }
          CompilerManagerHook.CdnMeta.getStdlibRuntimeUrl(compilerVersion, filename)
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
