/** Copy a homepage command and opt in to React Compiler for client builds. */
@react.component
let make: (
  ~code: string,
  ~writeClipboard: string => promise<result<unit, Clipboard.error>>=?,
) => React.element
