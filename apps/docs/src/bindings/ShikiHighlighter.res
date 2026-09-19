@module("../server/ShikiHighlighter.js")
external highlight: (~code: string, ~language: string) => string = "highlight"
