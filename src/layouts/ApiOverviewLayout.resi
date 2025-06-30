module Docs: {
  @react.component
  let make: (
    ~version: string,
    ~components: MarkdownComponents.t=?,
    ~children: React.element,
  ) => React.element
}
