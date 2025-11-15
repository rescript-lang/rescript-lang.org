@react.component
let make: (~components: MarkdownComponents.t=?, ~children: React.element) => React.element

module Layout: {
  @react.component
  let make: unit => React.element
}
