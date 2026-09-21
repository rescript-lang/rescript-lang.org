let expectedExample = `module Button = {
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
}`

let expectedJavascript = `import * as JsxRuntime from "react/jsx-runtime";

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
}`

let playgroundData = LandingPagePlaygroundLoader.build()
