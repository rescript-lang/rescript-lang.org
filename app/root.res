@module("../styles/main.css?url")
external mainCss: string = "default"

@module("../styles/_hljs.css?url")
external hljsCss: string = "default"

@module("../styles/utils.css?url")
external utilsCss: string = "default"

%%raw(`
  import hljs from 'highlight.js/lib/core';
  import bash from 'highlight.js/lib/languages/bash';
  import css from 'highlight.js/lib/languages/css';
  import diff from 'highlight.js/lib/languages/diff';
  import javascript from 'highlight.js/lib/languages/javascript';
  import json from 'highlight.js/lib/languages/json';
  import text from 'highlight.js/lib/languages/plaintext';
  import html from 'highlight.js/lib/languages/xml';
  import rescript from 'highlightjs-rescript';

  hljs.registerLanguage('rescript', rescript)
  hljs.registerLanguage('javascript', javascript)
  hljs.registerLanguage('css', css)
  hljs.registerLanguage('ts', javascript)
  hljs.registerLanguage('sh', bash)
  hljs.registerLanguage('json', json)
  hljs.registerLanguage('text', text)
  hljs.registerLanguage('html', html)
  hljs.registerLanguage('diff', diff)
`)

open ReactRouter

@react.component
let default = () => {
  let (isOverlayOpen, setOverlayOpen) = React.useState(_ => false)
  <html>
    <head>
      <style> {React.string("html {opacity:0;}")} </style>
      <link rel="preconnect" href={mainCss} />
      <link rel="stylesheet" href={mainCss} />

      <Links />
      <Meta />
      <link rel="stylesheet" href={hljsCss} />
      <link rel="stylesheet" href={utilsCss} />
      <link rel="icon" href="/favicon.ico" />
      <meta
        name="viewport"
        content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, minimal-ui"
      />
      <meta charSet="UTF-8" />
    </head>
    <body>
      <Navigation isOverlayOpen setOverlayOpen />
      <Outlet />
      <ScrollRestoration />
      <Scripts />
    </body>
  </html>
}
