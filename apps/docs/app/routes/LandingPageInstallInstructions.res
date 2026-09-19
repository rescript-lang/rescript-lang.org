let copyBox = text => {
  <div
    className="relative flex justify-between items-center pl-6 pr-3 py-3 w-full bg-gray-10 border border-gray-20 rounded max-w-400"
  >
    <span className="font-mono text-14 text-gray-70"> {React.string(text)} </span>
    <LandingPageCopyButton code=text />
  </div>
}

@react.component
let make = (~className="") => {
  <div className={`w-full max-w-400 ${className}`}>
    <h2 className="hl-3 lg:mt-12"> {React.string("Quick Install")} </h2>
    <div className="captions text-gray-40 mb-2 mt-1">
      {React.string(
        "You can quickly add ReScript to your existing JavaScript codebase via npm / yarn:",
      )}
    </div>
    {copyBox("npm install rescript")}
    <div className="captions text-gray-40 mb-2 mt-2">
      {React.string("Or generate a new project from the official template with npx:")}
    </div>
    {copyBox("npx create-rescript-app")}
  </div>
}
