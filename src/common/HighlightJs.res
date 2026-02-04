type options = {language: string}

@deriving(abstract)
type highlightResult = {value: string}

@module("highlight.js/lib/core") @scope("default")
external highlight: (~code: string, ~options: options) => highlightResult = "highlight"

let renderHLJS = (~highlightedLines=[], ~darkmode=false, ~code: string, ~lang: string, ()) => {
  // If the language couldn't be parsed, we will fall back to text
  let options = {language: lang}
  let (lang, highlighted) = try (lang, highlight(~code, ~options)->valueGet) catch {
  | JsExn(_) => ("text", code)
  }

  // Add line highlighting as well
  let highlighted = if Array.length(highlightedLines) > 0 {
    String.split(highlighted, "\n")
    ->Array.mapWithIndex((line, i) =>
      if Array.find(highlightedLines, lnum => lnum === i + 1) !== None {
        let content = line === "" ? "&nbsp;" : line
        "<span className=\"inline-block\">" ++ (content ++ "</span>")
      } else {
        "<span className=\"inline-block text-inherit opacity-50\">" ++ (line ++ "</span>")
      }
    )
    ->Array.join("\n")
  } else {
    highlighted
  }

  let dark = darkmode ? "dark" : ""

  <code
    className={"hljs lang-" ++ (lang ++ (" " ++ dark))}
    dangerouslySetInnerHTML={"__html": highlighted}
  />
}
