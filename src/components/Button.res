type kind = PrimaryRed | PrimaryBlue | SecondaryRed
type size = Small | Large
/* type theme = Light | Dark */

@react.component
let make = (
  ~kind: kind=PrimaryRed,
  ~size: size=Large,
  ~children,
  ~onClick: option<JsxEvent.Mouse.t => unit>=?,
) => {
  let bgColor = switch kind {
  | PrimaryRed => "bg-fire hover:bg-fire-70 text-white"
  | PrimaryBlue => "bg-sky hover:bg-sky-70 text-white"
  | SecondaryRed => "border-fire-30 text-red hover:bg-fire-5"
  }

  let padding = switch size {
  | Large => "px-8 py-4 rounded-lg"
  | Small => "px-4 py-2 captions rounded"
  }

  <button
    ?onClick
    role="button"
    className={`select-none hover:cursor-pointer transition-colors duration-200 body-button focus:outline-none ${bgColor} ${padding}`}>
    children
  </button>
}
