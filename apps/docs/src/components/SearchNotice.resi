@react.component
let make: (~kind: [#Loading | #Unavailable], ~onClose: unit => unit) => React.element
