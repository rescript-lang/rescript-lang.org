type example = {
  res: string,
  js: string,
}

let examples = [
  {
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
  var count = props.count;
  var times = count !== 1 ? (
    count !== 2 ? count.toString() + " times" : "twice"
  ) : "once";
  var text = "Click me " + times;
  return JsxRuntime.jsx("button", {
    children: text
  });
}

var Button = {
  make: Playground$Button
};

export {
  Button,
}`,
  },
]

@react.component
let make = () => {
  let (example, _setExample) = React.useState(_ => examples->Array.getUnsafe(0))

  //Playground Section & Background
  <section className="relative mt-20 bg-gray-10">
    <div className="relative flex justify-center w-full">
      <div className="relative w-full pt-6 pb-8 sm:px-8 md:px-16 max-w-[1400px]">
        // Playground widget
        <div
          className="relative z-2 flex flex-col md:flex-row bg-gray-90 mx-auto sm:rounded-lg max-w-1280"
        >
          //Left Side (ReScript)
          <div className="md:w-1/2">
            <div
              className="body-sm text-gray-40 text-center py-3 sm:rounded-t-lg md:rounded-tl-lg bg-gray-100"
            >
              {React.string("Write in ReScript")}
            </div>
            <pre className="text-14 px-8 pt-6 pb-12 whitespace-pre-wrap">
              {HighlightJs.renderHLJS(~darkmode=true, ~code=example.res, ~lang="res", ())}
            </pre>
          </div>
          //Right Side (JavaScript)
          <div className="md:w-1/2 ">
            <div
              className="body-sm text-gray-40 py-3 text-center md:border-l border-gray-80 bg-gray-100 sm:rounded-tr-lg"
            >
              {React.string("Compile to JavaScript")}
            </div>
            <pre className="text-14 px-8 pt-6 pb-14 md:border-l border-gray-80 whitespace-pre-wrap">
              {HighlightJs.renderHLJS(~darkmode=true, ~code=example.js, ~lang="js", ())}
            </pre>
          </div>
        </div>

        /* ---Link to Playground--- */
        <div>
          <ReactRouter.Link.String
            to={`/try?code=${encodeURIComponent(example.res)}}`}
            className="captions md:px-0 border-b border-gray-40 hover:border-gray-60 text-gray-60"
          >
            {React.string("Edit this example in Playground")}
          </ReactRouter.Link.String>
        </div>
        //
        <div className="hidden md:block">
          <img className="absolute z-0 left-0 top-0 -ml-10 -mt-6 h-96 w-96" src="/lp/grid.svg" />
          <img className="absolute z-0 left-0 top-0 -ml-10 mt-10" src="/lp/illu_left.avif" />
        </div>
        <div className="hidden md:block">
          <img
            className="absolute z-0 right-0 bottom-0 -mb-10 mt-24 -mr-10 h-96 w-96"
            src="/lp/grid.svg"
          />
          <img className="absolute z-3 right-0 bottom-0 -mr-2 mb-10" src="/lp/illu_right.avif" />
        </div>
      </div>
    </div>
  </section>
}
