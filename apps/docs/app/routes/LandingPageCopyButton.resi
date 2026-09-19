@react.component
let make: (
  ~code: string,
  ~writeClipboard: string => promise<result<unit, Clipboard.error>>=?,
) => React.element
