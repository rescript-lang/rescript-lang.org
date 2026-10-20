@react.component
let make = (~children: React.element, ~onClose: unit => unit) =>
  <RescriptReactErrorBoundary fallback={_ => <SearchNotice kind=#Unavailable onClose />}>
    children
  </RescriptReactErrorBoundary>
