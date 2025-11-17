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
  ~value: string,
  // props for codemirror options
  ~mode: string,
  ~readOnly: bool=?,
  ~lineNumbers: bool=?,
  ~keyMap: KeyMap.t=?,
  ~lineWrapping: bool=?,
) => React.element
