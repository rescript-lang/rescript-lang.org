@module("react-markdown") @react.component
external make: (
  ~children: string,
  ~components: 'components=?,
  ~rehypePlugins: array<'plugin>=?,
) => React.element = "default"
