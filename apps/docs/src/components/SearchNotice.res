let loadingText = "Loading search"
let unavailableText = "Search unavailable"

@react.component
let make = (~kind, ~onClose: unit => unit) => {
  let (role, text) = switch kind {
  | #Loading => ("status", loadingText)
  | #Unavailable => ("alert", unavailableText)
  }

  <div
    role
    className="fixed top-6 left-1/2 z-1000 flex w-[calc(100%-2rem)] max-w-2xl -translate-x-1/2 items-center justify-between gap-4 rounded-sm border border-gray-20 bg-white px-4 py-3 shadow-lg"
  >
    <span className="text-14 font-medium text-gray-80"> {React.string(text)} </span>
    <button
      type_="button"
      ariaLabel="Close search"
      className="text-gray-60 hover:text-fire-50 cursor-pointer"
      onClick={_ => onClose()}
    >
      <Icon.Close className="h-4 w-4 stroke-current" />
    </button>
  </div>
}
