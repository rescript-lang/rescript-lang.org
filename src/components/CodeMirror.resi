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

type editorInstance

type editorConfig = {
  parent: WebAPI.DOMAPI.element,
  initialValue: string,
  mode: string,
  readOnly: bool,
  lineNumbers: bool,
  lineWrapping: bool,
  keyMap: KeyMap.t,
  onChange?: string => unit,
  errors: array<Error.t>,
  hoverHints: array<HoverHint.t>,
  minHeight?: string,
  maxHeight?: string,
}

let createEditor: editorConfig => editorInstance

let editorSetErrors: (editorInstance, array<Error.t>) => unit
let editorSetMode: (editorInstance, string) => unit
let editorSetKeyMap: (editorInstance, KeyMap.t) => unit
let editorDestroy: editorInstance => unit
let editorSetValue: (editorInstance, string) => unit
let editorGetValue: editorInstance => string
let editorSetHoverHints: (editorInstance, array<HoverHint.t>) => unit
