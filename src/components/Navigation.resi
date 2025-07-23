@react.component
let make: (
  ~fixed: bool=?,
  ~isOverlayOpen: bool,
  ~setOverlayOpen: (bool => bool) => unit,
) => React.element
