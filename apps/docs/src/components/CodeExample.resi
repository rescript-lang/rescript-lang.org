@react.component
let make: (
  ~highlightedLines: array<int>=?,
  ~code: string,
  ~showLabel: bool=?,
  ~lang: string=?,
  ~showCopyButton: bool=?,
) => React.element

module Toggle: {
  type tab = {
    highlightedLines: option<array<int>>,
    label: option<string>,
    lang: option<string>,
    code: string,
  }

  @react.component
  let make: (~tabs: array<tab>) => React.element
}
