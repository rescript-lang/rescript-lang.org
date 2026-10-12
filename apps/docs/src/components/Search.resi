type modal = React.component<SearchModal.props<string, string, string, unit => unit>>
type state = Inactive | Active(modal)
type action = Open(modal) | Close

let reduce: (state, action) => state

@react.component
let make: unit => React.element
