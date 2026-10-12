@module("react-markdown") @react.component
external make: (
  ~children: string,
  ~components: MarkdownComponents.t=?,
  ~rehypePlugins: array<Rehype.rehypePlugin>=?,
) => React.element = "default"
