@module("@mdx-js/react") @react.component
external make: (~components: MarkdownComponents.t, ~children: React.element=?) => React.element =
  "MDXProvider"
