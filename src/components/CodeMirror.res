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

// Raw JavaScript to create and manage CodeMirror 6 editor
let createEditor = %raw(`
  function(config) {
    const {
      parent,
      initialValue,
      mode,
      readOnly,
      lineNumbers,
      lineWrapping,
      keyMap,
      onChange,
      errors,
      hoverHints,
      minHeight,
      maxHeight
    } = config;
    
    // Import CodeMirror 6 modules
    const { EditorView, lineNumbers: lineNumbersExt, highlightActiveLine, highlightActiveLineGutter, drawSelection, dropCursor, keymap } = require("@codemirror/view");
    const { EditorState, Compartment } = require("@codemirror/state");
    const { defaultKeymap, historyKeymap, history } = require("@codemirror/commands");
    const { searchKeymap, highlightSelectionMatches } = require("@codemirror/search");
    const { syntaxHighlighting, defaultHighlightStyle, HighlightStyle, bracketMatching } = require("@codemirror/language");
    const { tags } = require("@lezer/highlight");
    const { linter, lintGutter } = require("@codemirror/lint");
    const { javascript } = require("@codemirror/lang-javascript");
    const { vim } = require("@replit/codemirror-vim");
    
    // Import custom language modes
    const { rescriptLanguage } = require("plugins/cm6-rescript-mode");
    const { reasonLanguage } = require("plugins/cm6-reason-mode");
    
    // Setup language based on mode
    let language;
    if (mode === "rescript") {
      language = rescriptLanguage;
    } else if (mode === "reason") {
      language = reasonLanguage;
    } else {
      language = javascript();
    }
    
    // Setup compartments for dynamic config
    const languageConf = new Compartment();
    const readOnlyConf = new Compartment();
    const keymapConf = new Compartment();
    
    // Basic extensions
    const extensions = [
      languageConf.of(language),
      history(),
      drawSelection(),
      dropCursor(),
      bracketMatching(),
      highlightSelectionMatches(),
      syntaxHighlighting(defaultHighlightStyle, {fallback: true}),
    ];
    
    // Add optional extensions
    if (lineNumbers) {
      extensions.push(lineNumbersExt());
      extensions.push(highlightActiveLineGutter());
    }
    
    if (!readOnly) {
      extensions.push(highlightActiveLine());
    }
    
    if (lineWrapping) {
      extensions.push(EditorView.lineWrapping);
    }
    
    // Add readonly conf
    extensions.push(readOnlyConf.of(EditorState.readOnly.of(readOnly)));
    
    // Add keymap
    let keymapValue = keyMap === "vim" 
      ? [vim(), ...defaultKeymap, ...historyKeymap, ...searchKeymap]
      : [...defaultKeymap, ...historyKeymap, ...searchKeymap];
    extensions.push(keymapConf.of(keymap.of(keymapValue)));
    
    // Add change listener
    if (onChange) {
      extensions.push(EditorView.updateListener.of((update) => {
        if (update.docChanged) {
          const newValue = update.state.doc.toString();
          onChange(newValue);
        }
      }));
    }
    
    // Add linter for errors
    if (errors && errors.length > 0) {
      extensions.push(linter((view) => {
        return errors.map(err => ({
          from: view.state.doc.line(err.row).from + err.column,
          to: view.state.doc.line(err.endRow).from + err.endColumn,
          severity: err.kind === 0 ? "error" : "warning",
          message: err.text
        }));
      }));
      extensions.push(lintGutter());
    }
    
    // Create editor
    const state = EditorState.create({
      doc: initialValue || "",
      extensions
    });
    
    const view = new EditorView({
      state,
      parent
    });
    
    // Apply custom styling
    if (minHeight) {
      view.dom.style.minHeight = minHeight;
    }
    if (maxHeight) {
      view.dom.style.maxHeight = maxHeight;
      view.dom.style.overflow = "auto";
    }
    
    // Return object with methods
    return {
      view,
      languageConf,
      readOnlyConf,
      keymapConf,
      setValue(value) {
        view.dispatch({
          changes: {from: 0, to: view.state.doc.length, insert: value}
        });
      },
      getValue() {
        return view.state.doc.toString();
      },
      destroy() {
        view.destroy();
      },
      setMode(newMode) {
        let newLang;
        if (newMode === "rescript") {
          newLang = rescriptLanguage;
        } else if (newMode === "reason") {
          newLang = reasonLanguage;
        } else {
          newLang = javascript();
        }
        view.dispatch({
          effects: languageConf.reconfigure(newLang)
        });
      },
      setKeyMap(newKeyMap) {
        const newKeymapValue = newKeyMap === "vim"
          ? [vim(), ...defaultKeymap, ...historyKeymap, ...searchKeymap]
          : [...defaultKeymap, ...historyKeymap, ...searchKeymap];
        view.dispatch({
          effects: keymapConf.reconfigure(keymap.of(newKeymapValue))
        });
      }
    };
  }
`)

@react.component
let make = (
  ~errors: array<Error.t>=[],
  ~hoverHints: array<HoverHint.t>=[],
  ~minHeight: option<string>=?,
  ~maxHeight: option<string>=?,
  ~className: option<string>=?,
  ~style: option<ReactDOM.Style.t>=?,
  ~onChange: option<string => unit>=?,
  ~onMarkerFocus as _: option<((int, int)) => unit>=?,
  ~onMarkerFocusLeave as _: option<((int, int)) => unit>=?,
  ~value: string,
  ~mode: string,
  ~readOnly=false,
  ~lineNumbers=true,
  ~scrollbarStyle="native",
  ~keyMap=KeyMap.Default,
  ~lineWrapping=false,
): React.element => {
  let containerRef = React.useRef(Nullable.null)
  let editorRef: React.ref<option<'a>> = React.useRef(None)
  let _windowWidth = useWindowWidth()

  // Initialize editor
  React.useEffect(() => {
    switch containerRef.current->Nullable.toOption {
    | Some(parent) =>
      let editor = %raw(`createEditor`)({
        "parent": parent,
        "initialValue": value,
        "mode": mode,
        "readOnly": readOnly,
        "lineNumbers": lineNumbers,
        "lineWrapping": lineWrapping,
        "keyMap": KeyMap.toString(keyMap),
        "onChange": onChange,
        "errors": errors,
        "hoverHints": hoverHints,
        "minHeight": minHeight,
        "maxHeight": maxHeight,
      })

      editorRef.current = Some(editor)

      Some(
        () => {
          %raw(`editor.destroy()`)
        },
      )
    | None => None
    }
  }, [keyMap])

  // Update value when it changes externally
  React.useEffect(() => {
    switch editorRef.current {
    | Some(_editor) =>
      let currentValue = %raw(`_editor.getValue()`)
      if currentValue !== value {
        %raw(`_editor.setValue`)(value)
      }
    | None => ()
    }
    None
  }, [value])

  // Update mode when it changes
  React.useEffect(() => {
    switch editorRef.current {
    | Some(_editor) => %raw(`_editor.setMode`)(mode)
    | None => ()
    }
    None
  }, [mode])

  <div ?className ?style ref={ReactDOM.Ref.domRef((Obj.magic(containerRef): React.ref<Nullable.t<Dom.element>>))} />
}
