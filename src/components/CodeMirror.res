/*
    CodeMirrorBase is a clientside only component that can not be used in a isomorphic environment.
    Within our Next project, you will be required to use the <CodeMirror/> component instead, which
    will lazily import the CodeMirrorBase via Next's `dynamic` component loading mechanisms.

    ! If you load this component in a Next page without using dynamic loading, you will get a SSR error !

    This file is providing the core functionality and logic of our CodeMirror instances.
    
    Migrated to CodeMirror 6
 */

module KeyMap = {
  type t = Default | Vim
  let toString = (keyMap: t) =>
    switch keyMap {
    | Default => "default"
    | Vim => "vim"
    }

  let fromString = (str: string) =>
    switch str {
    | "vim" => Vim
    | _ => Default
    }
}

let useWindowWidth: unit => int = %raw(`() => {
  const isClient = typeof window === 'object';

  function getSize() {
    return {
      width: isClient ? window.innerWidth : 0,
      height: isClient ? window.innerHeight : 0
    };
  }

  const [windowSize, setWindowSize] = React.useState(getSize);

  let throttled = false;
  React.useEffect(() => {
    if (!isClient) {
      return false;
    }

    function handleResize() {
      if(!throttled) {
        setWindowSize(getSize());

        throttled = true;
        setTimeout(() => { throttled = false }, 300);
      }
    }

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []); // Empty array ensures that effect is only run on mount and unmount

  if(windowSize) {
    return windowSize.width;
  }
  return null;
}
`)

module Error = {
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

module HoverHint = {
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

// CodeMirror 6 bindings
module CM6 = {
  type extension
  type editorState
  type editorView
  type compartment
  type effect

  type keymapSpec

  module Extension = {
    type t = extension
    external fromArray: array<t> => t = "%identity"
  }

  module Text = {
    type t
    type line
    @send external toString: t => string = "toString"
    @get external lines: t => int = "lines"
    @send external line: (t, int) => line = "line"
    @get external lineFrom: line => int = "from"
    @get external lineLength: line => int = "length"
  }

  module EditorState = {
    type createConfig = {doc: string, extensions: array<extension>}

    @module("@codemirror/state") @scope("EditorState")
    external create: createConfig => editorState = "create"

    module ReadOnly = {
      @module("@codemirror/state") @scope(("EditorState", "readOnly")) @val
      external of_: bool => extension = "of"
    }
    @get external doc: editorState => Text.t = "doc"
  }

  module Compartment = {
    @module("@codemirror/state") @new
    external create: unit => compartment = "Compartment"
    @send external make: (compartment, extension) => extension = "of"
    @send external reconfigure: (compartment, extension) => effect = "reconfigure"
  }

  module EditorView = {
    type createConfig = {state: editorState, parent: WebAPI.DOMAPI.element}
    @module("@codemirror/view") @new
    external create: createConfig => editorView = "EditorView"

    @send external destroy: editorView => unit = "destroy"
    @get external state: editorView => editorState = "state"
    @get external dom: editorView => WebAPI.DOMAPI.htmlElement = "dom"

    type change = {from: int, to: int, insert: string}
    type dispatchArg = {changes: change}
    @send
    external dispatch: (editorView, dispatchArg) => unit = "dispatch"

    type dispatchEffectsArg = {effects: effect}
    @send
    external dispatchEffects: (editorView, dispatchEffectsArg) => unit = "dispatch"

    @module("@codemirror/view") @scope("EditorView") @val
    external lineWrapping: extension = "lineWrapping"

    @module("@codemirror/view")
    external lineNumbers: unit => extension = "lineNumbers"

    @module("@codemirror/view")
    external highlightActiveLine: unit => extension = "highlightActiveLine"

    @module("@codemirror/view")
    external highlightActiveLineGutter: unit => extension = "highlightActiveLineGutter"

    @module("@codemirror/view")
    external drawSelection: unit => extension = "drawSelection"

    @module("@codemirror/view")
    external dropCursor: unit => extension = "dropCursor"

    module UpdateListener = {
      type update
      @get external view: update => editorView = "view"
      @get external docChanged: update => bool = "docChanged"

      @module("@codemirror/view") @scope(("EditorView", "updateListener"))
      external of_: (update => unit) => extension = "of"
    }
  }

  module Commands = {
    @module("@codemirror/commands")
    external history: unit => extension = "history"

    @module("@codemirror/commands") @val
    external defaultKeymap: array<keymapSpec> = "defaultKeymap"

    @module("@codemirror/commands") @val
    external historyKeymap: array<keymapSpec> = "historyKeymap"
  }

  module Search = {
    @module("@codemirror/search") @val
    external searchKeymap: array<keymapSpec> = "searchKeymap"

    @module("@codemirror/search")
    external highlightSelectionMatches: unit => extension = "highlightSelectionMatches"
  }

  module Language = {
    @module("@codemirror/language")
    external bracketMatching: unit => extension = "bracketMatching"

    type syntaxConfig = {fallback: bool}

    @module("@codemirror/language")
    external syntaxHighlighting: (extension, syntaxConfig) => extension = "syntaxHighlighting"

    @module("@codemirror/language") @val
    external defaultHighlightStyle: extension = "defaultHighlightStyle"
  }

  module Keymap = {
    @module("@codemirror/view") @scope("keymap") @val
    external of_: array<keymapSpec> => extension = "of"
  }

  module Lint = {
    type diagnostic = {
      from: int,
      to: int,
      severity: string,
      message: string,
    }

    type linterSource = editorView => array<diagnostic>

    @module("@codemirror/lint")
    external linter: linterSource => extension = "linter"

    @module("@codemirror/lint")
    external lintGutter: unit => extension = "lintGutter"
  }

  module JavaScript = {
    @module("@codemirror/lang-javascript")
    external javascript: unit => extension = "javascript"
  }

  module Vim = {
    @module("@replit/codemirror-vim")
    external vim: unit => extension = "vim"
  }

  module CustomLanguages = {
    @module("../../plugins/cm6-rescript-mode.js") @val
    external rescriptLanguage: extension = "rescriptLanguage"

    @module("../../plugins/cm6-reason-mode.js") @val
    external reasonLanguage: extension = "reasonLanguage"
  }
}

type editorInstance = {
  view: CM6.editorView,
  languageConf: CM6.compartment,
  readOnlyConf: CM6.compartment,
  keymapConf: CM6.compartment,
  lintConf: CM6.compartment,
}

type editorConfig = {
  parent: WebAPI.DOMAPI.element,
  initialValue: string,
  mode: string,
  readOnly: bool,
  lineNumbers: bool,
  lineWrapping: bool,
  keyMap: string,
  onChange: option<string => unit>,
  errors: array<Error.t>,
  hoverHints: array<HoverHint.t>,
  minHeight: option<string>,
  maxHeight: option<string>,
}

let createLinterExtension = (errors: array<Error.t>): CM6.extension => {
  let linterSource = (view: CM6.editorView): array<CM6.Lint.diagnostic> => {
    if Array.length(errors) === 0 {
      []
    } else {
      let doc = CM6.EditorView.state(view)->CM6.EditorState.doc
      let diagnostics = []

      Array.forEach(errors, err => {
        try {
          // Error row/endRow are 1-based (same as CodeMirror 5)
          // Error column/endColumn are 0-based (same as CodeMirror 5)
          let fromLine = Math.Int.max(1, Math.Int.min(err.row, CM6.Text.lines(doc)))
          let toLine = Math.Int.max(1, Math.Int.min(err.endRow, CM6.Text.lines(doc)))

          let startLine = CM6.Text.line(doc, fromLine)
          let endLine = CM6.Text.line(doc, toLine)

          let fromCol = Math.Int.max(0, Math.Int.min(err.column, CM6.Text.lineLength(startLine)))
          let toCol = Math.Int.max(0, Math.Int.min(err.endColumn, CM6.Text.lineLength(endLine)))

          let diagnostic = {
            CM6.Lint.from: CM6.Text.lineFrom(startLine) + fromCol,
            to: CM6.Text.lineFrom(endLine) + toCol,
            severity: err.kind === #Error ? "error" : "warning",
            message: err.text,
          }

          Array.push(diagnostics, diagnostic)
        } catch {
        | _ => Console.warn("Error creating lint marker")
        }
      })

      diagnostics
    }
  }

  CM6.Lint.linter(linterSource)
}

let createEditor = (config: editorConfig): editorInstance => {
  // Setup language based on mode
  let language = switch config.mode {
  | "rescript" => CM6.CustomLanguages.rescriptLanguage
  | "reason" => CM6.CustomLanguages.reasonLanguage
  | _ => CM6.JavaScript.javascript()
  }

  // Setup compartments for dynamic config
  let languageConf = CM6.Compartment.create()
  let readOnlyConf = CM6.Compartment.create()
  let keymapConf = CM6.Compartment.create()
  let lintConf = CM6.Compartment.create()

  // Basic extensions
  let extensions = [
    CM6.Compartment.make(languageConf, (language: CM6.extension)),
    CM6.Commands.history(),
    CM6.EditorView.drawSelection(),
    CM6.EditorView.dropCursor(),
    CM6.Language.bracketMatching(),
    CM6.Search.highlightSelectionMatches(),
    CM6.Language.syntaxHighlighting(CM6.Language.defaultHighlightStyle, {fallback: true}),
  ]

  // Add optional extensions
  if config.lineNumbers {
    Array.push(extensions, CM6.EditorView.lineNumbers())
    Array.push(extensions, CM6.EditorView.highlightActiveLineGutter())
  }

  if !config.readOnly {
    Array.push(extensions, CM6.EditorView.highlightActiveLine())
  }

  if config.lineWrapping {
    Array.push(extensions, CM6.EditorView.lineWrapping)
  }

  // Add readonly conf
  Array.push(
    extensions,
    CM6.Compartment.make(readOnlyConf, CM6.EditorState.ReadOnly.of_(config.readOnly)),
  )

  // Add keymap
  let keymapExtension = if config.keyMap === "vim" {
    let vimExt = CM6.Vim.vim()
    let defaultKeymapExt = CM6.Keymap.of_(CM6.Commands.defaultKeymap)
    let historyKeymapExt = CM6.Keymap.of_(CM6.Commands.historyKeymap)
    let searchKeymapExt = CM6.Keymap.of_(CM6.Search.searchKeymap)
    // Return vim extension combined with keymap extensions
    // We need to wrap them in an array and convert to extension
    /* combine extensions into a JS array value */
    [vimExt, defaultKeymapExt, historyKeymapExt, searchKeymapExt]->CM6.Extension.fromArray
  } else {
    let defaultKeymapExt = CM6.Keymap.of_(CM6.Commands.defaultKeymap)
    let historyKeymapExt = CM6.Keymap.of_(CM6.Commands.historyKeymap)
    let searchKeymapExt = CM6.Keymap.of_(CM6.Search.searchKeymap)
    // Return combined keymap extensions as a JS array
    [defaultKeymapExt, historyKeymapExt, searchKeymapExt]->CM6.Extension.fromArray
  }
  Array.push(extensions, CM6.Compartment.make(keymapConf, keymapExtension))

  // Add change listener
  switch config.onChange {
  | Some(onChange) =>
    let updateListener = CM6.EditorView.UpdateListener.of_(update => {
      if CM6.EditorView.UpdateListener.docChanged(update) {
        let view = CM6.EditorView.UpdateListener.view(update)
        let newValue = CM6.EditorView.state(view)->CM6.EditorState.doc->CM6.Text.toString
        onChange(newValue)
      }
    })
    Array.push(extensions, updateListener)
  | None => ()
  }

  // Add linter for errors (wrap the raw linter extension in the compartment)
  Array.push(extensions, CM6.Compartment.make(lintConf, createLinterExtension(config.errors)))
  Array.push(extensions, CM6.Lint.lintGutter())

  // Create editor
  let state = CM6.EditorState.create({doc: config.initialValue, extensions})

  let view = CM6.EditorView.create({state, parent: config.parent})

  // Apply custom styling
  let dom = CM6.EditorView.dom(view)
  switch config.minHeight {
  | Some(minHeight) => dom.style.minHeight = minHeight
  | None => ()
  }
  switch config.maxHeight {
  | Some(maxHeight) =>
    dom.style.maxHeight = maxHeight
    dom.style.overflow = "auto"
  | None => ()
  }

  {
    view,
    languageConf,
    readOnlyConf,
    keymapConf,
    lintConf,
  }
}

let editorSetValue = (instance: editorInstance, value: string): unit => {
  let doc = CM6.EditorView.state(instance.view)->CM6.EditorState.doc
  CM6.EditorView.dispatch(
    instance.view,
    {changes: {from: 0, to: CM6.Text.toString(doc)->String.length, insert: value}},
  )
}

let editorGetValue = (instance: editorInstance): string => {
  CM6.EditorView.state(instance.view)->CM6.EditorState.doc->CM6.Text.toString
}

let editorDestroy = (instance: editorInstance): unit => {
  CM6.EditorView.destroy(instance.view)
}

let editorSetMode = (instance: editorInstance, mode: string): unit => {
  let language = switch mode {
  | "rescript" => CM6.CustomLanguages.rescriptLanguage
  | "reason" => CM6.CustomLanguages.reasonLanguage
  | _ => CM6.JavaScript.javascript()
  }

  CM6.EditorView.dispatchEffects(
    instance.view,
    {effects: CM6.Compartment.reconfigure(instance.languageConf, (language: CM6.extension))},
  )
}

let editorSetErrors = (instance: editorInstance, errors: array<Error.t>): unit => {
  CM6.EditorView.dispatchEffects(
    instance.view,
    {
      effects: CM6.Compartment.reconfigure(instance.lintConf, createLinterExtension(errors)),
    },
  )
}

@react.component
let make = (
  ~errors: array<Error.t>=[],
  ~hoverHints: array<HoverHint.t>=[],
  ~minHeight: option<string>=?,
  ~maxHeight: option<string>=?,
  ~className: option<string>=?,
  ~style: option<ReactDOM.Style.t>=?,
  ~onChange: option<string => unit>=?,
  // Note: onMarkerFocus/onMarkerFocusLeave are kept for backward compatibility but not yet implemented in v6
  // These callbacks were used in v5 for hovering over error markers
  ~onMarkerFocus as _: option<((int, int)) => unit>=?,
  ~onMarkerFocusLeave as _: option<((int, int)) => unit>=?,
  ~value: string,
  ~mode: string,
  ~readOnly=false,
  ~lineNumbers=true,
  // Note: scrollbarStyle is deprecated in CodeMirror 6 but kept for backward compatibility (ignored)
  ~scrollbarStyle as _=?,
  ~keyMap=KeyMap.Default,
  ~lineWrapping=false,
): React.element => {
  let containerRef = React.useRef(Nullable.null)
  let editorRef: React.ref<option<editorInstance>> = React.useRef(None)
  let _windowWidth = useWindowWidth()

  // Initialize editor
  React.useEffect(() => {
    switch containerRef.current->Nullable.toOption {
    | Some(parent) =>
      let config: editorConfig = {
        parent,
        initialValue: value,
        mode,
        readOnly,
        lineNumbers,
        lineWrapping,
        keyMap: KeyMap.toString(keyMap),
        onChange,
        errors,
        hoverHints,
        minHeight,
        maxHeight,
      }

      let editor = createEditor(config)
      editorRef.current = Some(editor)

      Some(() => editorDestroy(editor))
    | None => None
    }
  }, [keyMap])

  // Update value when it changes externally
  React.useEffect(() => {
    switch editorRef.current {
    | Some(editor) =>
      let currentValue = editorGetValue(editor)
      if currentValue !== value {
        editorSetValue(editor, value)
      }
    | None => ()
    }
    None
  }, [value])

  // Update mode when it changes
  React.useEffect(() => {
    switch editorRef.current {
    | Some(editor) => editorSetMode(editor, mode)
    | None => ()
    }
    None
  }, [mode])

  // Update errors when they change
  React.useEffect(() => {
    switch editorRef.current {
    | Some(editor) => editorSetErrors(editor, errors)
    | None => ()
    }
    None
  }, [errors])

  <div
    ?className
    ?style
    ref={ReactDOM.Ref.domRef((Obj.magic(containerRef): React.ref<Nullable.t<Dom.element>>))}
  />
}
