type kind = [#Subtle]

@react.component
let make: (~text: string, ~kind: kind=?) => React.element
