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
  let highlighter = HighlightJsBindings.make()
  highlighter->HighlightJsBindings.registerLanguage("rescript", HighlightJsBindings.rescript)
  highlighter->HighlightJsBindings.registerLanguage("javascript", HighlightJsBindings.javascript)

  {
    rescriptHtml: (
      highlighter->HighlightJsBindings.highlight(example.res, {language: "rescript"})
    ).value,
    javascriptHtml: (
      highlighter->HighlightJsBindings.highlight(example.js, {language: "javascript"})
    ).value,
    playgroundHref: `/try?code=${LzString.lzString.compressToEncodedURIComponent(example.res)}`,
  }
}
