@react.component
let make: (
  ~apiKey: string,
  ~appId: string,
  ~indexName: string,
  ~onClose: unit => unit,
) => React.element
