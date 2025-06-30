@react.component
let make: (
  ~components: MarkdownComponents.t=?,
  ~version: string,
  ~children: React.element,
) => React.element
