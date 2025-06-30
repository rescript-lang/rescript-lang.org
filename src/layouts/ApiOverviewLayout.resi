module Docs: {
  @react.component
  let make: (
    ~version: Url.t,
    ~components: MarkdownComponents.t=?,
    ~children: React.element,
  ) => React.element
}
