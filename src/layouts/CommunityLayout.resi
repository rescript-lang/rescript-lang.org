@react.component
let make: (
  ~frontmatter: JSON.t=?,
  ~components: MarkdownComponents.t=?,
  ~children: React.element,
) => React.element
