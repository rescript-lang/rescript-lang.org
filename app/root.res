%%raw(`
  import "../styles/main.css";
  import "../styles/_hljs.css";
  import "../styles/utils.css";

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
      <Links />
      <Meta />
      <link rel="icon" href="/favicon.ico" />
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
