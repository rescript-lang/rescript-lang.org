@react.component
let make = (~compilerState, ~appendLog) => {
  let validReact = switch compilerState {
  | CompilerManagerHook.Executing({state: {validReactCode: true}})
  | Compiling({state: {validReactCode: true}})
  | Ready({validReactCode: true}) => true
  | _ => false
  }

  let logs = switch compilerState {
  | CompilerManagerHook.Executing({state: {logs}})
  | Compiling({state: {logs}})
  | Ready({logs}) => logs
  | _ => []
  }
  <div className="h-full flex flex-col overflow-y-hidden">
    <RenderPanel validReact />
    <hr className="border-gray-60" />
    <ConsolePanel logs appendLog />
  </div>
}
