@react.component
let make = (~output: GuideCompilerFeedback.Output.t) => {
  <div className="guide-output">
    {switch output.status {
    | "Output" => React.null
    | status => <div className="guide-output-status"> {React.string(status)} </div>
    }}
    {switch output.diagnostics {
    | [] => React.null
    | diagnostics =>
      <div className="guide-output-group">
        <div className="guide-output-heading"> {React.string("Diagnostics")} </div>
        {diagnostics
        ->Array.mapWithIndex((diagnostic, index) =>
          <pre key={index->Int.toString} className="guide-output-line guide-output-line-error">
            {React.string(diagnostic)}
          </pre>
        )
        ->React.array}
      </div>
    }}
    {switch output.runtimeLogs {
    | [] => React.null
    | runtimeLogs =>
      <div className="guide-output-group">
        <div className="guide-output-heading"> {React.string("Result")} </div>
        {runtimeLogs
        ->Array.mapWithIndex(({level, content}, index) =>
          <pre
            key={index->Int.toString}
            className={switch level {
            | #log => "guide-output-line"
            | #warn => "guide-output-line guide-output-line-warning"
            | #error => "guide-output-line guide-output-line-error"
            }}
          >
            {React.string(content->Array.join(" "))}
          </pre>
        )
        ->React.array}
      </div>
    }}
  </div>
}
