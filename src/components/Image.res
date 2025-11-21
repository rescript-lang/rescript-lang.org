@react.component
let default = (
  ~src: string,
  ~size=#large,
  ~withShadow=false,
  ~caption: option<string>=?,
  ~className: option<string>=?,
) => {
  <Markdown.Image src size withShadow ?caption ?className />
}
