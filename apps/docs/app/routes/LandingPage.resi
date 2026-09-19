type example = {
  res: string,
  js: string,
}

type highlightedExample = {
  res: string,
  js: string,
}

let playgroundExample: example

@react.component
let make: (
  ~components: MarkdownComponents.t=?,
  ~highlightedExample: highlightedExample,
) => React.element
