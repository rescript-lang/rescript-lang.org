type logLevel = [
  | #log
  | #warn
  | #error
]
type log = {level: logLevel, content: array<string>}

@react.component
let make = (~logs, ~appendLog) => {
  React.useEffect(() => {
    let cb = e => {
      let data = e["data"]
      switch data["type"] {
      | #...logLevel as logLevel =>
        let args: array<string> = data["args"]
        appendLog(logLevel, args)
      | _ => ()
      }
    }
    WebAPI.Window.addEventListener(window, WebAPI.EventAPI.Custom("message"), cb)
    Some(() => WebAPI.Window.removeEventListener(window, WebAPI.EventAPI.Custom("message"), cb))
  }, [appendLog])

  <div className="px-2 py-6 relative flex flex-col flex-1 overflow-y-hidden">
    <h2 className="font-bold text-gray-5/50 absolute right-2 top-2"> {React.string("Console")} </h2>
    {switch logs {
    | [] =>
      <p className="p-4 max-w-prose">
        {React.string(
          "Add some 'Console.log' to your code and click 'Run' or enable 'Auto-run' to see your logs here.",
        )}
      </p>
    | logs =>
      let content =
        logs
        ->Array.mapWithIndex(({level: logLevel, content: log}, i) => {
          let log = Array.join(log, " ")
          <pre
            key={Int.toString(i)}
            className={switch logLevel {
            | #log => ""
            | #warn => "text-orange"
            | #error => "text-fire"
            }}>
            {React.string(log)}
          </pre>
        })
        ->React.array

      <div className="whitespace-pre-wrap p-4 overflow-auto"> content </div>
    }}
  </div>
}
