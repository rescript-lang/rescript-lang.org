// CodeMirror 6 Reason language mode
// Adapted from the CodeMirror 5 version

import { StreamLanguage } from "@codemirror/language";

const reasonLanguage = StreamLanguage.define({
  name: "reason",
  startState: () => ({ tokenize: null, context: [] }),
  
  token(stream, state) {
    // Handle whitespace
    if (stream.eatSpace()) return null;

    // Handle comments
    if (stream.match("//")) {
      stream.skipToEnd();
      return "comment";
    }
    if (stream.match("/*")) {
      state.tokenize = tokenComment;
      return state.tokenize(stream, state);
    }

    // Handle strings
    if (stream.match(/^b?"/)) {
      state.tokenize = tokenString;
      return state.tokenize(stream, state);
    }

    // Handle character literals
    if (stream.match(/'(?:[^'\\]|\\(?:[nrt0'"]|x[\da-fA-F]{2}|u\{[\da-fA-F]{6}\}))'/)) {
      return "string-2";
    }

    // Handle byte literals
    if (stream.match(/b'(?:[^']|\\(?:['\\nrt0]|x[\da-fA-F]{2}))'/)) {
      return "string-2";
    }

    // Handle numbers
    if (stream.match(/^(?:(?:[0-9][0-9_]*)(?:(?:[Ee][+-]?[0-9_]+)|\.[0-9_]+(?:[Ee][+-]?[0-9_]+)?)(?:f32|f64)?)|(?:0(?:b[01_]+|(?:o[0-7_]+)|(?:x[0-9a-fA-F_]+))|(?:[0-9][0-9_]*))(?:u8|u16|u32|u64|i8|i16|i32|i64|isize|usize)?/)) {
      return "number";
    }

    // Handle let/type definitions
    if (stream.match(/^(let|type)(\s+rec)?(\s+)/)) {
      stream.match(/[a-zA-Z_][a-zA-Z0-9_]*/);
      return "keyword";
    }

    // Handle keywords
    if (stream.match(/^(?:switch|module|as|do|else|external|for|if|in|loop|mod|pub|ref|type|while|open|open\!)\b/)) {
      return "keyword";
    }

    // Handle rec keyword
    if (stream.match(/^(?:rec)\b/)) {
      return "keyword";
    }

    // Handle atoms
    if (stream.match(/^(?:char|bool|option|int|string)\b/)) {
      return "atom";
    }

    // Handle booleans
    if (stream.match(/^(?:true|false)\b/)) {
      return "builtin";
    }

    // Handle fun definitions
    if (stream.match(/^fun\s+/)) {
      stream.match(/[a-zA-Z_\|][a-zA-Z0-9_]*/);
      return "keyword";
    }

    // Handle module references
    if (stream.match(/^[A-Z][a-zA-Z0-9_]*\./)) {
      return "namespace";
    }

    // Handle variant constructors
    if (stream.match(/^[A-Z][a-zA-Z0-9_]*/)) {
      return "typeName";
    }

    // Handle operators
    if (stream.match(/^[-+\/*=<>!\|]+/)) {
      return "operator";
    }

    // Handle identifiers
    if (stream.match(/^[a-zA-Z_]\w*/)) {
      return "variableName";
    }

    // Move forward if nothing matched
    stream.next();
    return null;
  },
  
  tokenTable: {
    comment: "comment",
    string: "string",
    "string-2": "string",
    number: "number",
    keyword: "keyword",
    atom: "atom",
    builtin: "builtin",
    namespace: "namespace",
    typeName: "typeName",
    operator: "operator",
    variableName: "variableName"
  }
});

function tokenString(stream, state) {
  let escaped = false;
  let next;
  while ((next = stream.next()) != null) {
    if (next === '"' && !escaped) {
      state.tokenize = null;
      break;
    }
    escaped = !escaped && next === "\\";
  }
  return "string";
}

function tokenComment(stream, state) {
  while (stream.next() != null) {
    if (stream.current().includes("*/")) {
      state.tokenize = null;
      break;
    }
  }
  return "comment";
}

export { reasonLanguage };
