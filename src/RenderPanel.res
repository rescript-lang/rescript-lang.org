@react.component
let make = (~validReact) => {
  <div className={`px-2 relative ${validReact ? "flex-1 py-2 overflow-y-auto" : "h-auto py-6"}`}>
    <h2 className="font-bold text-gray-5/50 absolute right-2 top-2"> {React.string("React")} </h2>
    {validReact
      ? React.null
      : React.string(
          "Create a React component called 'App' if you want to render it here, then click 'Run' or enable 'Auto-run'.",
        )}
    <div className={validReact ? "h-full" : "h-0"}>
      <EvalIFrame />
    </div>
  </div>
}
