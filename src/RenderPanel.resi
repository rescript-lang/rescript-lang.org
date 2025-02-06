@react.component
let make: (
  ~compilerState: CompilerManagerHook.state,
  ~clearLogs: unit => unit,
  ~runOutput: bool,
) => Jsx.element
