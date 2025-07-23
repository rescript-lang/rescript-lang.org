module KeyMap: {
  type t = Default | Vim
  let toString: t => string
  let fromString: string => t
}

module Error: {
  type kind = [#Error | #Warning]

  type t = {
    row: int,
    column: int,
    endRow: int,
    endColumn: int,
    text: string,
    kind: kind,
  }
}

module HoverHint: {
  type position = {
    line: int,
    col: int,
  }

  type t = {
    start: position,
    end: position,
    hint: string,
  }
}

/* The module for interacting with the imperative CodeMirror API */
module CM: {
  module Options: {
    type t

    let t: (
      ~theme: string,
      ~gutters: array<string>=?,
      ~mode: string,
      ~lineNumbers: bool=?,
      ~readOnly: bool=?,
      ~lineWrapping: bool=?,
      ~fixedGutter: bool=?,
      ~scrollbarStyle: string=?,
      ~keyMap: string=?,
      unit,
    ) => t
  }
}

let useWindowWidth: unit => int

@react.component
let make: (
  ~errors: array<Error.t>=?,
  ~hoverHints: array<HoverHint.t>=?,
  ~minHeight: string=?,
  ~maxHeight: string=?,
  ~className: string=?,
  ~style: ReactDOM.Style.t=?,
  ~onChange: string => unit=?,
  ~onMarkerFocus: ((int, int)) => unit=?, // (row, column)
  ~onMarkerFocusLeave: ((int, int)) => unit=?, // (row, column)
  ~value: string,
  // props for codemirror options
  ~mode: string,
  ~readOnly: bool=?,
  ~lineNumbers: bool=?,
  ~scrollbarStyle: string=?,
  ~keyMap: KeyMap.t=?,
  ~lineWrapping: bool=?,
) => React.element
