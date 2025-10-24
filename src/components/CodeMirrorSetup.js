// CodeMirror setup and mode imports
import CodeMirror from "codemirror";

import "codemirror/lib/codemirror.css";

// Import required modes and addons
import "codemirror/mode/javascript/javascript";
import "../../plugins/cm-rescript-mode.js";
import "../../plugins/cm-reason-mode.js";

// Import vim keymap if needed
import "codemirror/keymap/vim";

// Make sure CodeMirror is available globally
if (typeof window !== "undefined") {
  window.CodeMirror = CodeMirror;
}

export default CodeMirror;
