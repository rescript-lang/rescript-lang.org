@react.component
let make: (
  ~components: MarkdownComponents.t=?,
  ~version: Url.t,
  ~children: React.element,
) => React.element
