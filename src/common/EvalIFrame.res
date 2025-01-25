let css = `body {
  background-color: inherit;
  color: CanvasText;
  color-scheme: light dark;
}`

let reactVersion = "18.2.0"

let srcDoc = `
    <html>
      <head>
        <meta charset="UTF-8" />
        <title>Playground Output</title>
        <style>${css}</style>
      </head>
      <body>
        <div id="root"></div>
        <script type="importmap">
          {
            "imports": {
              "react-dom/client": "https://esm.sh/react-dom@${reactVersion}/client",
              "react": "https://esm.sh/react@${reactVersion}",
              "react/jsx-runtime": "https://esm.sh/react@${reactVersion}/jsx-runtime"
            }
          }
        </script>
        <script type="module">
          import * as ReactDOM from 'react-dom/client';
          import * as React from 'react';
          import * as JsxRuntime from 'react/jsx-runtime';
          const container = document.getElementById("root");
          const root = ReactDOM.createRoot(container);
          window.reactRoot = root;
          window.React = React;
          window.JsxRuntime = JsxRuntime;
        </script>
        <script>
          window.addEventListener("message", async (event) => {
            try {
              // https://rollupjs.org/troubleshooting/#avoiding-eval
              const imports = {};
              for (const [key, path] of Object.entries(event.data.imports)) {
                imports[key] = await import(path);
              }
              (Function(...Object.keys(imports), event.data.code))(...Object.values(imports));
            } catch (err) {
              console.error(err);
            }
          });
          const sendLog = (logLevel) => (...args) => {
            let finalArgs = args.map(arg => {
              if (arg === undefined) {
                return 'undefined';
              }
              else if (typeof arg === 'object') {
                return JSON.stringify(arg, Object.getOwnPropertyNames(arg));
              } else if (typeof arg === 'function') {
                return arg.toString()
              }
              return arg;
            });
            parent.window.postMessage({ type: logLevel, args: finalArgs }, '*');
          };
          console.log = sendLog('log');
          console.warn = sendLog('warn');
          console.error = sendLog('error');
        </script>
      </body>
    </html>
  `

type message = {
  code: string,
  imports: Dict.t<string>,
}

let sendOutput = (code, imports) => {
  open Webapi

  let frame = Document.document->Element.getElementById("iframe-eval")

  switch frame {
  | Value(element) =>
    switch element->Element.contentWindow {
    | Some(win) => win->Element.postMessageAny({code, imports}, ~targetOrigin="*")
    | None => Console.error("contentWindow not found")
    }
  | Null | Undefined => Console.error("iframe not found")
  }
}

@react.component
let make = () => {
  <iframe width="100%" id="iframe-eval" className="relative h-full w-full text-gray-20" srcDoc />
}
