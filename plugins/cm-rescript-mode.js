// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: https://codemirror.net/LICENSE
//
// Originally derived from the CodeMirror Rust plugin:
// https://github.com/codemirror/CodeMirror/blob/master/mode/rust/rust.js

import "codemirror/addon/mode/simple";
import CodeMirror from "codemirror/lib/codemirror";

CodeMirror.defineSimpleMode("rescript", {
  start: [
    // string and byte string
    { regex: /b?"/, token: "string", next: "string" },
    // raw string and raw byte string
    //{ regex: /b?r"/, token: "string", next: "string_raw" },
    //{ regex: /b?r#+"/, token: "string", next: "string_raw_hash" },
    // string and byte string
    { regex: /b?"/, token: "string", next: "string" },
    { regex: /(\:\s*)(.*)(\s*=)\s/, token: [null, "type-annotation", null] },
    // interpolation string
    { regex: /b?`/, token: "string", next: "string_interpolation" },
    // character
    {
      regex: /'(?:[^'\\]|\\(?:[nrt0'"]|x[\da-fA-F]{2}|u\{[\da-fA-F]{6}\}))'/,
      token: "string-2",
    },
    // byte
    { regex: /b'(?:[^']|\\(?:['\\nrt0]|x[\da-fA-F]{2}))'/, token: "string-2" },
    {
      regex:
        /(?:(?:[0-9][0-9_]*)(?:(?:[Ee][+-]?[0-9_]+)|\.[0-9_]+(?:[Ee][+-]?[0-9_]+)?)(?:f32|f64)?)|(?:0(?:b[01_]+|(?:o[0-7_]+)|(?:x[0-9a-fA-F_]+))|(?:[0-9][0-9_]*))(?:u8|u16|u32|u64|i8|i16|i32|i64|isize|usize)?/,
      token: "number",
    },
    {
      regex: /(let|type)(\s+rec)?(\s+)([a-zA-Z_][a-zA-Z0-9_]*)/,
      token: ["keyword", "keyword2", null, "def"],
    },
    {
      regex:
        /(?:and|as|assert|catch|async|await|constraint|downto|else|exception|export|external|false|for|if|import|in|include|lazy|let|module|mutable|of|open|private|switch|to|true|try|type|when|while|with\!)\b/,
      token: "keyword",
    },
    {
      regex: /(?:rec|list)\b/,
      token: "keyword2",
    },
    {
      regex: /\b(?:char|bool|option|int|string)\b/,
      token: "atom",
    },
    { regex: /\b(?:true|false)\b/, token: "builtin" },
    {
      regex: /\b([A-Z][a-zA-Z0-9_]*)(\.)/,
      token: ["module", null],
    },
    {
      regex: /\b([A-Z][a-zA-Z0-9_]*)/,
      token: ["variant-constructor", null, null, null],
    },
    //polyvar
    { regex: /#[a-zA-Z0-9_"]*/, token: "variant-constructor" },
    { regex: /@.[\w\.\(\)]*/, token: "decorator" },
    { regex: /#!?\[.*\]/, token: "meta" },
    { regex: /\/\/.*/, token: "comment" },
    { regex: /\/\*/, token: "comment", next: "comment" },
    { regex: /[-+\/*=<>!\|]+/, token: "operator" },
    { regex: /[a-zA-Z_]\w*!/, token: "variable-3" },
    { regex: /[a-zA-Z_]\w*/, token: "variable" },
    { regex: /[\{\[\(]/, indent: true },
    { regex: /[\}\]\)]/, dedent: true },
  ],
  variantConstructor: [],
  string: [
    { regex: /"/, token: "string", next: "start" },
    { regex: /(?:[^\\"]|\\(?:.|$))*/, token: "string" },
  ],
  //string_raw: [
  //{ regex: /"/, token: "string", next: "start" },
  //{ regex: /[^"]*/, token: "string" }
  //],
  //string_raw_hash: [
  //{ regex: /"#+/, token: "string", next: "start" },
  //{ regex: /(?:[^"]|"(?!#))*/, token: "string" }
  //],
  list: [
    { regex: /list{/, token: "keyword2", next: "start" },
    { regex: /[^`]*/, token: "string" },
  ],
  string_interpolation: [
    { regex: /`/, token: "string", next: "start" },
    { regex: /[^`]*/, token: "string" },
  ],
  comment: [
    { regex: /.*?\*\//, token: "comment", next: "start" },
    { regex: /.*/, token: "comment" },
  ],
  meta: {
    dontIndentStates: ["comment"],
    electricInput: /^\s*\}$/,
    blockCommentStart: "/*",
    blockCommentEnd: "*/",
    lineComment: "//",
    fold: "brace",
  },
});

CodeMirror.defineMIME("text/x-reasonsrc", "reason");
CodeMirror.defineMIME("text/reason", "reason");
