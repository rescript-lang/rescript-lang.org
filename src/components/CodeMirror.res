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

  module Common = {
    type nodePropSource
  }

  module Language = {
    module HighlightStyle = {
      type tag
      module Tags = {
        @@warning("-32") // Suppress "unused external" warnings
        @module("@lezer/highlight") @scope("tags")
        external comment: tag = "comment"
        @module("@lezer/highlight") @scope("tags")
        external lineComment: tag = "lineComment"
        @module("@lezer/highlight") @scope("tags")
        external blockComment: tag = "blockComment"
        @module("@lezer/highlight") @scope("tags")
        external docComment: tag = "docComment"
        @module("@lezer/highlight") @scope("tags")
        external name: tag = "name"
        @module("@lezer/highlight") @scope("tags")
        external variableName: tag = "variableName"
        @module("@lezer/highlight") @scope("tags")
        external typeName: tag = "typeName"
        @module("@lezer/highlight") @scope("tags")
        external tagName: tag = "tagName"
        @module("@lezer/highlight") @scope("tags")
        external propertyName: tag = "propertyName"
        @module("@lezer/highlight") @scope("tags")
        external attributeName: tag = "attributeName"
        @module("@lezer/highlight") @scope("tags")
        external className: tag = "className"
        @module("@lezer/highlight") @scope("tags")
        external labelName: tag = "labelName"
        @module("@lezer/highlight") @scope("tags")
        external namespace: tag = "namespace"
        @module("@lezer/highlight") @scope("tags")
        external macroName: tag = "macroName"
        @module("@lezer/highlight") @scope("tags")
        external literal: tag = "literal"
        @module("@lezer/highlight") @scope("tags")
        external string: tag = "string"
        @module("@lezer/highlight") @scope("tags")
        external docString: tag = "docString"
        @module("@lezer/highlight") @scope("tags")
        external character: tag = "character"
        @module("@lezer/highlight") @scope("tags")
        external attributeValue: tag = "attributeValue"
        @module("@lezer/highlight") @scope("tags")
        external number: tag = "number"
        @module("@lezer/highlight") @scope("tags")
        external integer: tag = "integer"
        @module("@lezer/highlight") @scope("tags")
        external float: tag = "float"
        @module("@lezer/highlight") @scope("tags")
        external bool: tag = "bool"
        @module("@lezer/highlight") @scope("tags")
        external regexp: tag = "regexp"
        @module("@lezer/highlight") @scope("tags")
        external escape: tag = "escape"
        @module("@lezer/highlight") @scope("tags")
        external color: tag = "color"
        @module("@lezer/highlight") @scope("tags")
        external url: tag = "url"
        @module("@lezer/highlight") @scope("tags")
        external keyword: tag = "keyword"
        @module("@lezer/highlight") @scope("tags")
        external self: tag = "self"
        @module("@lezer/highlight") @scope("tags")
        external null: tag = "null"
        @module("@lezer/highlight") @scope("tags")
        external atom: tag = "atom"
        @module("@lezer/highlight") @scope("tags")
        external unit: tag = "unit"
        @module("@lezer/highlight") @scope("tags")
        external modifier: tag = "modifier"
        @module("@lezer/highlight") @scope("tags")
        external operatorKeyword: tag = "operatorKeyword"
        @module("@lezer/highlight") @scope("tags")
        external controlKeyword: tag = "controlKeyword"
        @module("@lezer/highlight") @scope("tags")
        external definitionKeyword: tag = "definitionKeyword"
        @module("@lezer/highlight") @scope("tags")
        external moduleKeyword: tag = "moduleKeyword"
        @module("@lezer/highlight") @scope("tags")
        external operator: tag = "operator"
        @module("@lezer/highlight") @scope("tags")
        external derefOperator: tag = "derefOperator"
        @module("@lezer/highlight") @scope("tags")
        external arithmeticOperator: tag = "arithmeticOperator"
        @module("@lezer/highlight") @scope("tags")
        external logicOperator: tag = "logicOperator"
        @module("@lezer/highlight") @scope("tags")
        external bitwiseOperator: tag = "bitwiseOperator"
        @module("@lezer/highlight") @scope("tags")
        external compareOperator: tag = "compareOperator"
        @module("@lezer/highlight") @scope("tags")
        external updateOperator: tag = "updateOperator"
        @module("@lezer/highlight") @scope("tags")
        external definitionOperator: tag = "definitionOperator"
        @module("@lezer/highlight") @scope("tags")
        external typeOperator: tag = "typeOperator"
        @module("@lezer/highlight") @scope("tags")
        external controlOperator: tag = "controlOperator"
        @module("@lezer/highlight") @scope("tags")
        external punctuation: tag = "punctuation"
        @module("@lezer/highlight") @scope("tags")
        external separator: tag = "separator"
        @module("@lezer/highlight") @scope("tags")
        external bracket: tag = "bracket"
        @module("@lezer/highlight") @scope("tags")
        external angleBracket: tag = "angleBracket"
        @module("@lezer/highlight") @scope("tags")
        external squareBracket: tag = "squareBracket"
        @module("@lezer/highlight") @scope("tags")
        external paren: tag = "paren"
        @module("@lezer/highlight") @scope("tags")
        external brace: tag = "brace"
        @module("@lezer/highlight") @scope("tags")
        external content: tag = "content"
        @module("@lezer/highlight") @scope("tags")
        external heading: tag = "heading"
        @module("@lezer/highlight") @scope("tags")
        external heading1: tag = "heading1"
        @module("@lezer/highlight") @scope("tags")
        external heading2: tag = "heading2"
        @module("@lezer/highlight") @scope("tags")
        external heading3: tag = "heading3"
        @module("@lezer/highlight") @scope("tags")
        external heading4: tag = "heading4"
        @module("@lezer/highlight") @scope("tags")
        external heading5: tag = "heading5"
        @module("@lezer/highlight") @scope("tags")
        external heading6: tag = "heading6"
        @module("@lezer/highlight") @scope("tags")
        external contentSeparator: tag = "contentSeparator"
        @module("@lezer/highlight") @scope("tags")
        external list: tag = "list"
        @module("@lezer/highlight") @scope("tags")
        external quote: tag = "quote"
        @module("@lezer/highlight") @scope("tags")
        external emphasis: tag = "emphasis"
        @module("@lezer/highlight") @scope("tags")
        external strong: tag = "strong"
        @module("@lezer/highlight") @scope("tags")
        external link: tag = "link"
        @module("@lezer/highlight") @scope("tags")
        external monospace: tag = "monospace"
        @module("@lezer/highlight") @scope("tags")
        external strikethrough: tag = "strikethrough"
        @module("@lezer/highlight") @scope("tags")
        external inserted: tag = "inserted"
        @module("@lezer/highlight") @scope("tags")
        external deleted: tag = "deleted"
        @module("@lezer/highlight") @scope("tags")
        external changed: tag = "changed"
        @module("@lezer/highlight") @scope("tags")
        external invalid: tag = "invalid"
        @module("@lezer/highlight") @scope("tags")
        external meta: tag = "meta"
        @module("@lezer/highlight") @scope("tags")
        external documentMeta: tag = "documentMeta"
        @module("@lezer/highlight") @scope("tags")
        external annotation: tag = "annotation"
        @module("@lezer/highlight") @scope("tags")
        external processingInstruction: tag = "processingInstruction"
        @module("@lezer/highlight") @scope("tags")
        external definition: tag => tag = "definition"
        @module("@lezer/highlight") @scope("tags")
        external constant: tag => tag = "constant"
        @module("@lezer/highlight") @scope("tags")
        external function: tag => tag = "function"
        @module("@lezer/highlight") @scope("tags")
        external standard: tag => tag = "standard"
        @module("@lezer/highlight") @scope("tags")
        external local: tag => tag = "local"
        @module("@lezer/highlight") @scope("tags")
        external special: tag => tag = "special"
      }
      module TagStyle = {
        type t = {
          tag: array<tag>,
          color?: string,
          fontStyle?: string,
          fontWeight?: string,
          textDecoration?: string,
        }
      }
      type t
      @scope("HighlightStyle") @module("@codemirror/language")
      external define: array<TagStyle.t> => t = "define"

      let default = define([
        {
          tag: [Tags.keyword],
          color: "#708",
        },
        {
          tag: [Tags.atom, Tags.bool, Tags.url, Tags.contentSeparator, Tags.labelName],
          color: "#219",
        },
        {
          tag: [Tags.literal, Tags.inserted],
          color: "#164",
        },
        {
          tag: [Tags.string, Tags.special(Tags.string), Tags.deleted],
          color: "#a11",
        },
        {
          tag: [Tags.regexp, Tags.escape],
          color: "#040",
        },
        {
          tag: [Tags.definition(Tags.variableName)],
          color: "#00f",
        },
        {
          tag: [Tags.local(Tags.variableName)],
          color: "#30a",
        },
        {
          tag: [Tags.typeName, Tags.namespace],
          color: "#085",
        },
        {
          tag: [Tags.special(Tags.variableName), Tags.macroName],
          color: "#256",
        },
        {
          tag: [Tags.definition(Tags.propertyName)],
          color: "#00c",
        },
        {
          tag: [Tags.comment],
          color: "#940",
        },
        {
          tag: [Tags.invalid],
          color: "#f00",
        },
      ])
    }

    type t
    @module("@codemirror/language")
    external bracketMatching: unit => extension = "bracketMatching"

    type syntaxConfig = {fallback: bool}

    @module("@codemirror/language")
    external syntaxHighlighting: (HighlightStyle.t, syntaxConfig) => extension =
      "syntaxHighlighting"

    module LanguageSupport = {
      @new @module("@codemirror/language")
      external make: (t, ~support: array<extension>=?) => extension = "LanguageSupport"
    }

    module LRParser = {
      type t

      module Config = {
        type t = {props?: array<Common.nodePropSource>}
      }

      @send
      external _configure: (t, Config.t) => t = "configure"
    }

    module LRLanguage = {
      type spec = {
        name: string,
        parser: LRParser.t,
        languageData?: 'a. {..} as 'a,
      }
      @scope("LRLanguage") @module("@codemirror/language")
      external define: spec => t = "define"
    }
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

module ReScript = {
  @module("@tsnobip/rescript-lezer")
  external parser: CM6.Language.LRParser.t = "parser"

  let language = CM6.Language.LRLanguage.define({
    name: "ReScript",
    parser,
  })

  let extension = CM6.Language.LanguageSupport.make(language)
}

let createEditor = (config: editorConfig): editorInstance => {
  // Setup language based on mode
  let language = switch config.mode {
  | "rescript" => ReScript.extension
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
    CM6.Language.syntaxHighlighting(CM6.Language.HighlightStyle.default, {fallback: true}),
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
  | "rescript" => ReScript.extension
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
  ~value: string,
  ~mode: string,
  ~readOnly=false,
  ~lineNumbers=true,
  ~keyMap=KeyMap.Default,
  ~lineWrapping=false,
): React.element => {
  let containerRef = React.useRef(Nullable.null)
  let editorRef: React.ref<option<editorInstance>> = React.useRef(None)

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
