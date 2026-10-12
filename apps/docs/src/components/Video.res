@react.component
let default = (~src: string, ~caption: option<string>=?) => {
  <Markdown.Video src ?caption />
}
