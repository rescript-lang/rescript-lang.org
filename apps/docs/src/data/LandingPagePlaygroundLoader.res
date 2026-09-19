type highlighter
type language
type highlightOptions = {language: string}
type highlightResult = {value: string}

@module("highlight.js/lib/core") @scope("default")
external createHighlighter: unit => highlighter = "newInstance"

@module("highlight.js/lib/languages/javascript")
external javascript: language = "default"

@module("highlightjs-rescript")
external rescript: language = "default"

@send
external registerLanguage: (highlighter, string, language) => unit = "registerLanguage"

@send
external highlight: (highlighter, string, highlightOptions) => highlightResult = "highlight"

type example = {
  res: string,
  js: string,
}

let example = {
  res: `module Button = {
  @react.component
  let make = (~count) => {
    let times = switch count {
    | 1 => "once"
    | 2 => "twice"
    | n => n->Int.toString ++ " times"
    }
    let text = \`Click me $\{times\}\`

    <button> {text->React.string} </button>
  }
}`,
  js: `import * as JsxRuntime from "react/jsx-runtime";

function Playground$Button(props) {
  let count = props.count;
  let times = count !== 1 ? (
    count !== 2 ? count.toString() + " times" : "twice"
  ) : "once";
  let text = "Click me " + times;
  return JsxRuntime.jsx("button", {
    children: text
  });
}

let Button = {
  make: Playground$Button
};

export {
  Button,
}`,
}

let build = (): LandingPagePlayground.playgroundData => {
  // Keep prerendering independent of global language registration and other routes.
  let highlighter = createHighlighter()
  highlighter->registerLanguage("rescript", rescript)
  highlighter->registerLanguage("javascript", javascript)

  {
    rescriptHtml: (highlighter->highlight(example.res, {language: "rescript"})).value,
    javascriptHtml: (highlighter->highlight(example.js, {language: "javascript"})).value,
    playgroundHref: `/try?code=${LzString.lzString.compressToEncodedURIComponent(example.res)}`,
  }
}
