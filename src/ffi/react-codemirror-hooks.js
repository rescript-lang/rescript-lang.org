//
// OBSOLETE!
//
// This file is reimplemented in common/CodeMirrorBase.re
// We keep this around for reference in case we find some
// bugs in the new implementation
//
import CodeMirror from "codemirror"
import "codemirror/lib/codemirror.css"
import { useEffect, useRef } from "react"

if (typeof window !== "undefined" && typeof window.navigator !== "undefined") {
  require("codemirror/mode/javascript/javascript")
  require("../plugins/cm-reason-mode")
}

function makeErrorMarker(cm) {
  const wrapper = cm.getWrapperElement()

  const msg = document.createElement("div")
  msg.className = "z-10 absolute px-2 rounded bg-fire-15"
  msg.innerHTML = "Some Error Message"
  msg.style.display = "none"

  const showMsg = () => {
    msg.style.display = "block"
  }

  const hideMsg = () => {
    msg.style.display = "none"
  }

  const marker = document.createElement("div")
  marker.className =
    "text-center text-fire font-bold bg-fire-15 rounded w-4 ml-2 hover:cursor-pointer"
  marker.innerHTML = "!"
  marker.onmouseover = function markerMouseOver() {
    const wrapperPos = wrapper.getBoundingClientRect()
    const pos = marker.getBoundingClientRect()

    msg.style.left = pos.x - wrapperPos.x + pos.width + "px"
    msg.style.top = pos.y - wrapperPos.y + "px"

    console.log("wrapperPos", wrapperPos)
    console.log("markerPos", pos)
    console.log(msg.style.left)

    showMsg()
  }

  marker.onmouseleave = function markerMouseLeave() {
    hideMsg()
  }

  wrapper.appendChild(msg)

  return marker
}

const ERROR_GUTTER_ID = "errors"

function clearMarks(cm) {
  var state = cm.state.errors

  for (var i = 0; i < state.marked.length; ++i) {
    state.marked[i].clear()
  }

  state.marked.length = 0
}

function updateErrors(cm, errors) {
  // Clear out all previous errors first
  clearMarks(cm)
  cm.clearGutter(ERROR_GUTTER_ID)

  const state = cm.state.errors

  errors.forEach((e) => {
    const marker = makeErrorMarker(cm)
    cm.setGutterMarker(e.row, ERROR_GUTTER_ID, marker)

    const from = { line: e.row, ch: e.column }
    const to = { line: e.endRow, ch: e.endColumn }

    state.marked.push(cm.markText(from, to, { className: "bg-fire-15" }))
    console.log("marked", state.marked)
  })

  //cm.setGutterMarker(0, ERROR_GUTTER_ID, marker);
}

export default function CodeMirrorReact(props) {
  const options = props.options || {}

  const errors = props.errors || []
  const value = props.value || ""

  const inputElement = useRef()
  const cmRef = useRef()

  useEffect(() => {
    const cm = CodeMirror.fromTextArea(inputElement.current, {
      theme: "material",
      gutters: [ERROR_GUTTER_ID, "CodeMirror-linenumbers"],
      ...options,
    })

    cm.getScrollerElement().style.minHeight = props.minHeight
    cm.refresh()

    // For some reason, injecting value with the options doesn't work
    // so we need to set the initial value imperatively
    cm.setValue(value)

    // Set up event handlers
    const onChange = props.onChange
    if (onChange != null) {
      cm.on("change", (instance, obj) => {
        onChange(instance.getValue())
      })
    }

    cmRef.current = cm

    // Set state
    cm.state.errors = { marked: [] }

    return () => {
      console.log("cleanup", options.mode)
      // This will destroy the CM instance
      cm.toTextArea()
    }
  }, [])

  useEffect(() => {
    const cm = cmRef.current

    if (cm != null) {
      cm.setValue(value)
    }
  }, [value])

  useEffect(() => {
    const cm = cmRef.current

    if (cm != null) {
      //console.log("setting errors");
      //console.log(errors);

      cm.operation(() => {
        updateErrors(cm, errors)
      })
    }
  }, [errors])

  return (
    <div className={props.className} style={props.style}>
      <textarea className="hidden" ref={inputElement} />
    </div>
  )
}
