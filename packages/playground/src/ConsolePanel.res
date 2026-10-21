type logLevel = RuntimeConsole.level
type log = RuntimeConsole.log = {level: logLevel, content: array<string>}

@react.component
let make = (~logs, ~appendLog) => {
  let onLog = React.useCallback(
    ({RuntimeConsole.level: level, content}) => appendLog(level, content),
    [appendLog],
  )
  RuntimeConsole.useLogs(onLog)

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
        ->Array.mapWithIndex((log, i) => {
          <pre
            key={Int.toString(i)}
            className={switch log.level {
            | #log => ""
            | #warn => "text-orange"
            | #error => "text-fire"
            }}
          >
            {React.string(RuntimeConsole.text(log))}
          </pre>
        })
        ->React.array

      <div className="whitespace-pre-wrap p-4 overflow-auto"> content </div>
    }}
  </div>
}
