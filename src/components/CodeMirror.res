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

module Side = {
  @@warning("-37")
  type t =
    | @as(-1) BeforePointer
    | @as(1) AfterPointer
}

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

  module Line = {
    type t = {
      from: int,
      @as("to") to_: int,
      number: int,
      text: string,
      length: int,
    }
  }

  module Text = {
    type t = {lines: int}
    @send external toString: t => string = "toString"
    @send external line: (t, int) => Line.t = "line"
    @send external lineAt: (t, int) => Line.t = "lineAt"
  }

  module EditorSelection = {
    type t
    type range
    @module("@codemirror/state") @scope("EditorSelection") @val
    external single: (int, int) => t = "single"
    @get external main: t => range = "main"
    @get external anchor: range => int = "anchor"
    @get external head: range => int = "head"
  }

  module EditorState = {
    type createConfig = {doc: string, extensions: array<extension>}

    @module("@codemirror/state") @scope("EditorState")
    external create: createConfig => editorState = "create"
    @get external selection: editorState => EditorSelection.t = "selection"

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
    module Tooltip = {
      module View = {
        type t = {dom: WebAPI.DOMAPI.element, offset?: {x: int, y: int}}
      }
      type t = {
        pos: int,
        end?: int,
        create: editorView => View.t,
        above?: bool,
        strictSide?: bool,
        arrow?: bool,
        clip?: bool,
      }
    }

    type createConfig = {state: editorState, parent: WebAPI.DOMAPI.element}
    @module("@codemirror/view") @new
    external create: createConfig => editorView = "EditorView"

    @send external destroy: editorView => unit = "destroy"
    @get external state: editorView => editorState = "state"
    @get external dom: editorView => WebAPI.DOMAPI.htmlElement = "dom"

    type change = {from: int, to: int, insert: string}
    type dispatchArg = {changes: change, selection?: EditorSelection.t}
    @send
    external dispatch: (editorView, dispatchArg) => unit = "dispatch"

    type dispatchEffectsArg = {effects: effect}
    @send
    external dispatchEffects: (editorView, dispatchEffectsArg) => unit = "dispatch"

    @module("@codemirror/view") @scope("EditorView") @val
    external theme: dict<dict<string>> => extension = "theme"

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

    @module("@codemirror/view")
    external hoverTooltip: ((editorView, int, Side.t) => null<Tooltip.t>) => extension =
      "hoverTooltip"

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
          class?: string,
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
          tag: [Tags.keyword, Tags.moduleKeyword, Tags.operator],
          class: "text-berry-dark-50",
        },
        {
          tag: [
            Tags.variableName,
            Tags.definition(Tags.propertyName),
            Tags.labelName,
            Tags.definition(Tags.typeName),
            Tags.special(Tags.angleBracket),
          ],
          class: "text-gray-30",
        },
        {
          tag: [Tags.bool, Tags.atom, Tags.typeName, Tags.special(Tags.tagName)],
          class: "text-orange-dark",
        },
        {
          tag: [Tags.string, Tags.special(Tags.string), Tags.number],
          class: "text-turtle-dark",
        },
        {
          tag: [Tags.comment],
          class: "text-gray-60",
        },
        {
          tag: [Tags.definition(Tags.namespace)],
          class: "text-orange",
        },
        {
          tag: [Tags.namespace],
          class: "text-water-dark",
        },
        {
          tag: [Tags.annotation, Tags.tagName],
          class: "text-ocean-dark",
        },
        {
          tag: [Tags.attributeName, Tags.labelName, Tags.definition(Tags.variableName)],
          color: "#bcc9ab",
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
    type severity =
      | @as("error") Error
      // | @as("hint") Hint
      // | @as("info") Info
      | @as("warning") Warning

    type diagnostic = {
      from: int,
      to: int,
      severity: severity,
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
  hintConf: CM6.compartment,
}

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

let createLinterExtension = (errors: array<Error.t>): CM6.extension => {
  let linterSource = (view: CM6.editorView): array<CM6.Lint.diagnostic> => {
    if Array.length(errors) === 0 {
      []
    } else {
      let doc = CM6.EditorView.state(view)->CM6.EditorState.doc
      let diagnostics = []

      Array.forEach(errors, err => {
        try {
          // Error row/endRow are 1-based (same as CodeMirror 6)
          // Error column/endColumn are 0-based (same as CodeMirror 6)
          let fromLine = Math.Int.max(1, Math.Int.min(err.row, doc.lines))
          let toLine = Math.Int.max(1, Math.Int.min(err.endRow, doc.lines))

          let startLine = CM6.Text.line(doc, fromLine)
          let endLine = CM6.Text.line(doc, toLine)

          let fromCol = Math.Int.max(0, Math.Int.min(err.column, startLine.length))
          let toCol = Math.Int.max(0, Math.Int.min(err.endColumn, endLine.length))

          let diagnostic = {
            CM6.Lint.from: startLine.from + fromCol,
            to: endLine.from + toCol,
            severity: switch err.kind {
            | #Error => Error
            | #Warning => Warning
            },
            message: err.text->Ansi.parse->Ansi.Printer.plainString,
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

let createHoverHintExtension = (hoverHints: array<HoverHint.t>) => {
  CM6.EditorView.hoverTooltip((view, pos, _side) => {
    let doc = view->CM6.EditorView.state->CM6.EditorState.doc
    let {number: line, from} = doc->CM6.Text.lineAt(pos)
    let col = pos - from
    let found = hoverHints->Array.find(({start, end}) => {
      line >= start.line && line <= end.line && col >= start.col && col <= end.col
    })
    switch found {
    | Some({hint, start, end}) =>
      let pos = CM6.Text.line(doc, start.line).from + start.col
      let end = CM6.Text.line(doc, end.line).from + end.col
      let dom = WebAPI.Global.document->WebAPI.Document.createElement("div")
      dom.textContent = Value(hint)
      dom.className = "p-1 border"
      Value({
        pos,
        end,
        above: true,
        create: _view => {dom: dom},
      })
    | None => Null
    }
  })
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

let keyMapToExtension = (keyMap: KeyMap.t) =>
  switch keyMap {
  | Vim =>
    let vimExt = CM6.Vim.vim()
    let defaultKeymapExt = CM6.Keymap.of_(CM6.Commands.defaultKeymap)
    let historyKeymapExt = CM6.Keymap.of_(CM6.Commands.historyKeymap)
    let searchKeymapExt = CM6.Keymap.of_(CM6.Search.searchKeymap)
    // Return vim extension combined with keymap extensions
    // We need to wrap them in an array and convert to extension
    /* combine extensions into a JS array value */
    [vimExt, defaultKeymapExt, historyKeymapExt, searchKeymapExt]->CM6.Extension.fromArray
  | _ =>
    let defaultKeymapExt = CM6.Keymap.of_(CM6.Commands.defaultKeymap)
    let historyKeymapExt = CM6.Keymap.of_(CM6.Commands.historyKeymap)
    let searchKeymapExt = CM6.Keymap.of_(CM6.Search.searchKeymap)
    // Return combined keymap extensions as a JS array
    [defaultKeymapExt, historyKeymapExt, searchKeymapExt]->CM6.Extension.fromArray
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
  let hintConf = CM6.Compartment.create()

  let lineHeight = "1.5"
  let cursorColor = "#dd8c1b"

  // Basic extensions
  let extensions = [
    CM6.Compartment.make(languageConf, (language: CM6.extension)),
    CM6.Commands.history(),
    CM6.EditorView.theme(
      dict{
        ".cm-content": dict{
          "lineHeight": lineHeight,
          "caretColor": cursorColor,
        },
        ".cm-line": dict{
          "lineHeight": lineHeight,
        },
        ".cm-cursor, .cm-dropCursor": dict{"borderLeftColor": cursorColor},
        ".cm-activeLine": dict{
          "backgroundColor": "rgba(255, 255, 255, 0.02)",
        },
        ".cm-gutters": dict{"backgroundColor": "inherit"},
        ".cm-gutters.cm-gutters-before": dict{"border": "none"},
        ".cm-activeLineGutter": dict{
          "color": "#cdcdd6",
          "backgroundColor": "inherit",
        },
        "&.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground, .cm-selectionBackground, .cm-content ::selection": dict{
          "backgroundColor": "rgba(255, 255, 255, 0.20)",
        },
        ".cm-selectionMatch": dict{"backgroundColor": "#aafe661a"},
      },
    ),
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
  let keymapExtension = keyMapToExtension(config.keyMap)
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
  Array.push(
    extensions,
    CM6.Compartment.make(hintConf, createHoverHintExtension(config.hoverHints)),
  )
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
    hintConf,
  }
}

type textDiff = {from: int, to: int, insert: string}

let computeDiff = (currentValue: string, nextValue: string): option<textDiff> => {
  if currentValue === nextValue {
    None
  } else {
    let currentLength = String.length(currentValue)
    let nextLength = String.length(nextValue)
    let minLength = currentLength < nextLength ? currentLength : nextLength

    let rec findStart = index =>
      if (
        index < minLength &&
          String.charCodeAtUnsafe(currentValue, index) === String.charCodeAtUnsafe(nextValue, index)
      ) {
        findStart(index + 1)
      } else {
        index
      }

    let startIndex = findStart(0)

    let rec findEnd = (currentIndex, nextIndex) =>
      if (
        currentIndex > startIndex &&
        nextIndex > startIndex &&
        String.charCodeAtUnsafe(currentValue, currentIndex - 1) ===
          String.charCodeAtUnsafe(nextValue, nextIndex - 1)
      ) {
        findEnd(currentIndex - 1, nextIndex - 1)
      } else {
        (currentIndex, nextIndex)
      }

    let (currentEnd, nextEnd) = findEnd(currentLength, nextLength)
    Some({
      from: startIndex,
      to: currentEnd,
      insert: String.slice(nextValue, ~start=startIndex, ~end=nextEnd),
    })
  }
}

let mapPosition = (~position, ~from, ~to, ~insertLength) => {
  if position <= from {
    position
  } else if position >= to {
    position + insertLength - (to - from)
  } else {
    from + Math.Int.min(insertLength, position - from)
  }
}

let editorGetValue = (instance: editorInstance): string => {
  CM6.EditorView.state(instance.view)->CM6.EditorState.doc->CM6.Text.toString
}

let editorSetValue = (instance: editorInstance, value: string): unit => {
  let currentValue = editorGetValue(instance)
  if currentValue !== value {
    switch computeDiff(currentValue, value) {
    | Some({from, to, insert}) =>
      let state = CM6.EditorView.state(instance.view)
      let selection = CM6.EditorState.selection(state)->CM6.EditorSelection.main
      let anchor = CM6.EditorSelection.anchor(selection)
      let head = CM6.EditorSelection.head(selection)
      let insertLength = String.length(insert)
      let mapToNewPosition = pos => mapPosition(~position=pos, ~from, ~to, ~insertLength)

      CM6.EditorView.dispatch(
        instance.view,
        {
          changes: {from, to, insert},
          selection: CM6.EditorSelection.single(mapToNewPosition(anchor), mapToNewPosition(head)),
        },
      )
    | None => ()
    }
  }
}

let editorDestroy = (instance: editorInstance): unit => {
  CM6.EditorView.destroy(instance.view)
}

let editorSetKeyMap = (instance: editorInstance, keyMap: KeyMap.t): unit => {
  CM6.EditorView.dispatchEffects(
    instance.view,
    {
      effects: CM6.Compartment.reconfigure(
        instance.keymapConf,
        (keyMap->keyMapToExtension: CM6.extension),
      ),
    },
  )
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

let editorSetHoverHints = (instance: editorInstance, hints: array<HoverHint.t>): unit => {
  CM6.EditorView.dispatchEffects(
    instance.view,
    {
      effects: CM6.Compartment.reconfigure(instance.hintConf, createHoverHintExtension(hints)),
    },
  )
}
