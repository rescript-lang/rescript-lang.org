/*
    CodeMirrorBase is a clientside only component that can not be used in a isomorphic environment.
    Within our Next project, you will be required to use the <CodeMirror/> component instead, which
    will lazily import the CodeMirrorBase via Next's `dynamic` component loading mechanisms.

    ! If you load this component in a Next page without using dynamic loading, you will get a SSR error !

    This file is providing the core functionality and logic of our CodeMirror instances.
 */

// TODO: post RR7: figure out how to do this inside of rescript
// Import CodeMirror setup to ensure modes are loaded
%%raw(`import "./CodeMirrorSetup.js"`)

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

let useWindowWidth: unit => int = %raw(` () => {
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

/* The module for interacting with the imperative CodeMirror API */
module CM = {
  type t

  let errorGutterId = "errors"

  module Options = {
    type t = {
      theme: string,
      gutters?: array<string>,
      mode: string,
      lineNumbers?: bool,
      readOnly?: bool,
      lineWrapping?: bool,
      fixedGutter?: bool,
      scrollbarStyle?: string,
      keyMap?: string,
    }
  }

  @module("codemirror")
  external onMouseOver: (
    WebAPI.DOMAPI.element,
    @as("mouseover") _,
    ReactEvent.Mouse.t => unit,
  ) => unit = "on"

  @module("codemirror")
  external onMouseMove: (
    WebAPI.DOMAPI.element,
    @as("mousemove") _,
    ReactEvent.Mouse.t => unit,
  ) => unit = "on"

  @module("codemirror")
  external offMouseOver: (
    WebAPI.DOMAPI.element,
    @as("mouseover") _,
    ReactEvent.Mouse.t => unit,
  ) => unit = "off"

  @module("codemirror")
  external offMouseOut: (
    WebAPI.DOMAPI.element,
    @as("mouseout") _,
    ReactEvent.Mouse.t => unit,
  ) => unit = "off"

  @module("codemirror")
  external offMouseMove: (
    WebAPI.DOMAPI.element,
    @as("mousemove") _,
    ReactEvent.Mouse.t => unit,
  ) => unit = "off"

  @module("codemirror")
  external onMouseOut: (
    WebAPI.DOMAPI.element,
    @as("mouseout") _,
    ReactEvent.Mouse.t => unit,
  ) => unit = "on"

  @module("codemirror")
  external fromTextArea: (WebAPI.DOMAPI.element, Options.t) => t = "fromTextArea"

  @send
  external setMode: (t, @as("mode") _, string) => unit = "setOption"

  @send
  external getScrollerElement: t => WebAPI.DOMAPI.element = "getScrollerElement"

  @send
  external getWrapperElement: t => WebAPI.DOMAPI.element = "getWrapperElement"

  @send external refresh: t => unit = "refresh"

  @send
  external onChange: (t, @as("change") _, t => unit) => unit = "on"

  @send external toTextArea: t => unit = "toTextArea"

  @send external setValue: (t, string) => unit = "setValue"

  @send external getValue: t => string = "getValue"

  @send
  external operation: (t, unit => unit) => unit = "operation"

  @send
  external setGutterMarker: (t, int, string, WebAPI.DOMAPI.element) => unit = "setGutterMarker"

  @send external clearGutter: (t, string) => unit = "clearGutter"

  type markPos = {
    line: int,
    ch: int,
  }

  module TextMarker = {
    type t

    @send external clear: t => unit = "clear"
  }

  module MarkTextOption = {
    type t

    module Attr = {
      type t
      @obj external make: (~id: string=?, unit) => t = ""
    }

    @obj
    external make: (~className: string=?, ~attributes: Attr.t=?, unit) => t = ""
  }

  @send
  external markText: (t, markPos, markPos, MarkTextOption.t) => TextMarker.t = "markText"

  @send
  external coordsChar: (t, {"top": int, "left": int}) => {"line": int, "ch": int} = "coordsChar"
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

module HoverTooltip = {
  type t = WebAPI.DOMAPI.element

  type state =
    | Hidden
    | Shown({
        el: WebAPI.DOMAPI.element,
        marker: CM.TextMarker.t,
        hoverHint: HoverHint.t,
        hideTimer: option<WebAPI.DOMAPI.timeoutId>,
      })

  let make = () => {
    let tooltip = WebAPI.Document.createElement(document, "div")
    tooltip.id = "hover-tooltip"
    tooltip.className = "absolute hidden select-none font-mono text-12 z-10 bg-sky-10 py-1 px-2 rounded"
    tooltip
  }

  let hide = (t: t) => WebAPI.DOMTokenList.add(t.classList, "hidden")

  let update = (t: t, ~top: int, ~left: int, ~text: string) => {
    let t = (Obj.magic(t): WebAPI.DOMAPI.htmlElement)
    t.style.left = `${left->Int.toString}px`
    t.style.top = `${top->Int.toString}px`
    t.classList->WebAPI.DOMTokenList.remove("hidden")
    t.innerHTML = text
  }

  let attach = (t: t) => WebAPI.Element.appendChild(document.body->Obj.magic, t)->ignore

  let clear = (t: t) => WebAPI.Element.remove(t->Obj.magic)
}

// We'll keep this tooltip instance outside the
// hook, so we don't need to use a React.ref to
// keep the instance around
let tooltip = HoverTooltip.make()

type state = {mutable marked: array<CM.TextMarker.t>, mutable hoverHints: array<HoverHint.t>}

let isSpanToken = (element: WebAPI.DOMAPI.element) =>
  element.tagName->String.toUpperCase === "SPAN" &&
    element->WebAPI.Element.getAttribute("role") !== Value("presentation")

let useHoverTooltip = (~cmStateRef: React.ref<state>, ~cmRef: React.ref<option<CM.t>>, ()) => {
  let stateRef = React.useRef(HoverTooltip.Hidden)

  let markerRef = React.useRef(None)

  React.useEffect(() => {
    tooltip->HoverTooltip.attach

    Some(
      () => {
        tooltip->HoverTooltip.clear
      },
    )
  }, [])

  let checkIfTextMarker = (element: WebAPI.DOMAPI.element) => {
    let isToken =
      element.tagName->String.toUpperCase === "SPAN" &&
        element->WebAPI.Element.getAttribute("role") !== Value("presentation")

    isToken && RegExp.test(/CodeMirror-hover-hint-marker/, element.className)
  }

  let onMouseOver = evt => {
    switch cmRef.current {
    | Some(cm) =>
      let target = (Obj.magic(ReactEvent.Mouse.target(evt)): WebAPI.DOMAPI.element)

      // If mouseover is triggered for a text marker, we don't want to trigger any logic
      if checkIfTextMarker(target) {
        ()
      } else if isSpanToken(target) {
        let {hoverHints} = cmStateRef.current
        let pageX = evt->ReactEvent.Mouse.pageX
        let pageY = evt->ReactEvent.Mouse.pageY

        let coords = cm->CM.coordsChar({"top": pageY, "left": pageX})

        let col = coords["ch"]
        let line = coords["line"] + 1

        let found = hoverHints->Array.find(item => {
          let {start, end} = item
          line >= start.line && line <= end.line && col >= start.col && col <= end.col
        })

        switch found {
        | Some(hoverHint) =>
          tooltip->HoverTooltip.update(~top=pageY - 35, ~left=pageX, ~text=hoverHint.hint)

          let from = {CM.line: hoverHint.start.line - 1, ch: hoverHint.start.col}
          let to_ = {CM.line: hoverHint.end.line - 1, ch: hoverHint.end.col}

          let markerObj = CM.MarkTextOption.make(
            ~className="CodeMirror-hover-hint-marker border-b",
            (),
          )

          switch stateRef.current {
          | Hidden =>
            let marker = cm->CM.markText(from, to_, markerObj)
            markerRef.current = Some(marker)
            stateRef.current = Shown({
              el: target,
              marker,
              hoverHint,
              hideTimer: None,
            })
          | Shown({el, marker: prevMarker, hideTimer}) =>
            switch hideTimer {
            | Some(timerId) => clearTimeout(timerId)
            | None => ()
            }
            CM.TextMarker.clear(prevMarker)
            let marker = cm->CM.markText(from, to_, markerObj)

            stateRef.current = Shown({
              el,
              marker,
              hoverHint,
              hideTimer: None,
            })
          }
        | None => ()
        }
      }
    | _ => ()
    }
    ()
  }

  let onMouseOut = _evt => {
    switch stateRef.current {
    | Shown({el, hoverHint, marker, hideTimer}) =>
      switch hideTimer {
      | Some(timerId) => clearTimeout(timerId)
      | None => ()
      }

      marker->CM.TextMarker.clear
      let timerId = setTimeout(~handler=() => {
        stateRef.current = Hidden
        tooltip->HoverTooltip.hide
      }, ~timeout=200)

      stateRef.current = Shown({
        el,
        hoverHint,
        marker,
        hideTimer: Some(timerId),
      })
    | _ => ()
    }
  }

  let onMouseMove = evt => {
    switch stateRef.current {
    | Shown({hoverHint}) =>
      let pageX = evt->ReactEvent.Mouse.pageX
      let pageY = evt->ReactEvent.Mouse.pageY

      tooltip->HoverTooltip.update(~top=pageY - 35, ~left=pageX, ~text=hoverHint.hint)
      ()
    | _ => ()
    }
  }

  (onMouseOver, onMouseOut, onMouseMove)
}

module GutterMarker = {
  // Note: this is not a React component
  let make = (~rowCol: (int, int), ~kind: Error.kind, ()): WebAPI.DOMAPI.element => {
    // row, col

    let marker = WebAPI.Document.createElement(document, "div")
    let colorClass = switch kind {
    | #Warning => "text-orange bg-orange-15"
    | #Error => "text-fire bg-fire-100"
    }

    let (row, col) = rowCol
    marker.id = `gutter-marker_${row->Int.toString}-${col->Int.toString}`
    marker.className =
      "flex items-center justify-center text-14 text-center ml-1 h-6 font-bold hover:cursor-pointer " ++
      colorClass

    marker.innerHTML = "!"

    marker
  }
}

let _clearMarks = (state: state): unit => {
  Array.forEach(state.marked, mark => mark->CM.TextMarker.clear)
  state.marked = []
}

let extractRowColFromId = (id: string): option<(int, int)> =>
  switch String.split(id, "_") {
  | [_, rowColStr] =>
    switch String.split(rowColStr, "-") {
    | [rowStr, colStr] =>
      let row = Int.fromString(rowStr)
      let col = Int.fromString(colStr)
      switch (row, col) {
      | (Some(row), Some(col)) => Some((row, col))
      | _ => None
      }
    | _ => None
    }
  | _ => None
  }

module ErrorHash = Belt.Id.MakeHashable({
  type t = int
  let hash = a => a
  let eq = (a, b) => a == b
})

let updateErrors = (
  ~state: state,
  ~onMarkerFocus=?,
  ~onMarkerFocusLeave as _=?,
  ~cm: CM.t,
  errors,
) => {
  Array.forEach(state.marked, mark => mark->CM.TextMarker.clear)

  let errorsMap = Belt.HashMap.make(~hintSize=Array.length(errors), ~id=module(ErrorHash))
  state.marked = []
  cm->CM.clearGutter(CM.errorGutterId)

  let wrapper = cm->CM.getWrapperElement

  Array.forEachWithIndex(errors, (e, idx) => {
    open Error

    if !Belt.HashMap.has(errorsMap, e.row) {
      let marker = GutterMarker.make(~rowCol=(e.row, e.column), ~kind=e.kind, ())
      Belt.HashMap.set(errorsMap, e.row, idx)
      WebAPI.Element.appendChild(wrapper, marker)->ignore

      // CodeMirrors line numbers are (strangely enough) zero based
      let row = e.row - 1
      let endRow = e.endRow - 1

      cm->CM.setGutterMarker(row, CM.errorGutterId, marker)

      let from = {CM.line: row, ch: e.column}
      let to_ = {CM.line: endRow, ch: e.endColumn}

      let markTextColor = switch e.kind {
      | #Error => "border-fire"
      | #Warning => "border-orange"
      }

      cm
      ->CM.markText(
        from,
        to_,
        CM.MarkTextOption.make(
          ~className="border-b border-dotted hover:cursor-pointer " ++ markTextColor,
          ~attributes=CM.MarkTextOption.Attr.make(
            ~id="text-marker_" ++ (Int.toString(e.row) ++ ("-" ++ (Int.toString(e.column) ++ ""))),
            (),
          ),
          (),
        ),
      )
      ->Array.push(state.marked, _)
      ->ignore
      ()
    }
  })

  let isMarkerId = id =>
    String.startsWith(id, "gutter-marker") || String.startsWith(id, "text-marker")

  WebAPI.Element.addEventListener(wrapper, Mouseover, (evt: WebAPI.UIEventsAPI.mouseEvent) => {
    let target = (Obj.magic(evt.target): Null.t<WebAPI.DOMAPI.element>)

    switch target {
    | Value(target) =>
      if isMarkerId(target.id) {
        switch extractRowColFromId(target.id) {
        | Some(rowCol) => Option.forEach(onMarkerFocus, cb => cb(rowCol))
        | None => ()
        }
      }
    | Null => ()
    }
  })

  WebAPI.Element.addEventListener(wrapper, Mouseout, (evt: WebAPI.UIEventsAPI.mouseEvent) => {
    let target = (Obj.magic(evt.target): Null.t<WebAPI.DOMAPI.element>)

    switch target {
    | Value(target) =>
      if isMarkerId(target.id) {
        switch extractRowColFromId(target.id) {
        | Some(rowCol) => Option.forEach(onMarkerFocus, cb => cb(rowCol))
        | None => ()
        }
      }
    | Null => ()
    }
  })
}

@react.component
let make = // props relevant for the react wrapper
(
  ~errors: array<Error.t>=[],
  ~hoverHints: array<HoverHint.t>=[],
  ~minHeight: option<string>=?,
  ~maxHeight: option<string>=?,
  ~className: option<string>=?,
  ~style: option<ReactDOM.Style.t>=?,
  ~onChange: option<string => unit>=?,
  ~onMarkerFocus: option<((int, int)) => unit>=?, // (row, column)
  ~onMarkerFocusLeave: option<((int, int)) => unit>=?, // (row, column)
  ~value: string,
  // props for codemirror options
  ~mode,
  ~readOnly=false,
  ~lineNumbers=true,
  ~scrollbarStyle="native",
  ~keyMap=KeyMap.Default,
  ~lineWrapping=false,
): React.element => {
  Console.debug("staring codemirror")
  let inputElement = React.useRef(Nullable.null)
  let cmRef: React.ref<option<CM.t>> = React.useRef(None)
  let cmStateRef = React.useRef({marked: [], hoverHints})

  let windowWidth = useWindowWidth()
  let (onMouseOver, onMouseOut, onMouseMove) = useHoverTooltip(~cmStateRef, ~cmRef, ())

  Console.debug2("Rendering Codemirror with value:", value)

  React.useEffect(() => {
    switch inputElement.current->Nullable.toOption {
    | Some(el) => Console.debug2("Codemirror input element", el)
    | None => Console.debug("Codemirror input element is null")
    }

    switch inputElement.current->Nullable.toOption {
    | Some(input) =>
      let options = {
        CM.Options.theme: "material",
        gutters: [CM.errorGutterId, "CodeMirror-linenumbers"],
        mode,
        lineWrapping,
        fixedGutter: false,
        readOnly,
        lineNumbers,
        scrollbarStyle,
        keyMap: KeyMap.toString(keyMap),
      }

      Console.debug2("options", options)

      let cm = CM.fromTextArea(input, options)

      Option.forEach(minHeight, minHeight => {
        let element = (Obj.magic(cm->CM.getScrollerElement): WebAPI.DOMAPI.htmlElement)
        element.style.minHeight = minHeight
      })

      Option.forEach(maxHeight, maxHeight => {
        let element = (Obj.magic(cm->CM.getScrollerElement): WebAPI.DOMAPI.htmlElement)
        element.style.maxHeight = maxHeight
      })

      Option.forEach(onChange, onValueChange =>
        cm->CM.onChange(instance => onValueChange(instance->CM.getValue))
      )

      // For some reason, injecting value with the options doesn't work
      // so we need to set the initial value imperatively
      cm->CM.setValue(value)

      let wrapper = cm->CM.getWrapperElement
      wrapper->CM.onMouseOver(onMouseOver)
      wrapper->CM.onMouseOut(onMouseOut)
      wrapper->CM.onMouseMove(onMouseMove)

      cmRef.current = Some(cm)

      Console.debug2("Codemirror instance", cm)

      let cleanup = () => {
        /* Console.log2("cleanup", options->CM.Options.mode); */
        CM.offMouseOver(wrapper, onMouseOver)
        CM.offMouseOut(wrapper, onMouseOut)
        CM.offMouseMove(wrapper, onMouseMove)

        // This will destroy the CM instance
        cm->CM.toTextArea
        cmRef.current = None
      }

      Some(cleanup)
    | None => None
    }
  }, [keyMap])

  React.useEffect(() => {
    cmStateRef.current.hoverHints = hoverHints
    None
  }, [hoverHints])

  /*
     Previously we did this in a useEffect([|value|) setup, but
     this issues for syncing up the current editor value state
     with the passed value prop.

     Example: Let's assume you press a format code button for a
     piece of code that formats to the same value as the previously
     passed value prop. Even though the source code looks different
     in the editor (as observed via getValue) it doesn't recognize
     that there is an actual change.

     By checking if the local state of the CM instance is different
     to the input value, we can sync up both states accordingly
 */
  switch cmRef.current {
  | Some(cm) =>
    if CM.getValue(cm) === value {
      ()
    } else {
      let state = cmStateRef.current
      cm->CM.operation(() =>
        updateErrors(~onMarkerFocus?, ~onMarkerFocusLeave?, ~state, ~cm, errors)
      )
      cm->CM.setValue(value)
    }
  | None => ()
  }

  /*
      This is required since the incoming error
      array is not guaranteed to be the same instance,
      so we need to make a single string that React's
      useEffect is able to act on for equality checks
 */
  let errorsFingerprint = Array.map(errors, e => {
    let {Error.row: row, column} = e
    `${row->Int.toString}-${column->Int.toString}`
  })->Array.join(";")

  React.useEffect(() => {
    let state = cmStateRef.current
    switch cmRef.current {
    | Some(cm) =>
      cm->CM.operation(() =>
        updateErrors(~onMarkerFocus?, ~onMarkerFocusLeave?, ~state, ~cm, errors)
      )
    | None => ()
    }
    None
  }, [errorsFingerprint])

  React.useEffect(() => {
    let cm = Option.getOrThrow(cmRef.current)
    cm->CM.setMode(mode)
    None
  }, [mode])

  /*
    Needed in case the className visually hides / shows
    a codemirror instance, or the window has been resized.
 */
  React.useEffect(() => {
    switch cmRef.current {
    | Some(cm) => cm->CM.refresh
    | None => ()
    }
    None
  }, (className, windowWidth))

  <div ?className ?style>
    <textarea
      className="hidden"
      ref={ReactDOM.Ref.domRef((Obj.magic(inputElement): React.ref<Nullable.t<Dom.element>>))}
    />
  </div>
}
