import { isRouteErrorResponse, Outlet, Scripts, useNavigate } from "react-router";
import { make as Navigation } from "../src/components/Navigation.mjs";
import "../styles/_hljs.css";
import "../styles/main.css";
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



export default function App() {
  return (
    <html>
      <head>
        <link
          rel="icon"
          href="data:image/x-icon;base64,AA"
        />
      </head>
      <body>
        <Navigation />
        <Outlet />
        <Scripts />
      </body>
    </html>
  );
}

export function ErrorBoundary({
  error,
}) {
  const navigate = useNavigate()
  if (isRouteErrorResponse(error)) {
    return (
      <>
        <h1>
          {error.status} {error.statusText}
        </h1>
        <p>{error.data}</p>
      </>
    );
  } else if (error instanceof Error) {
    return (
      <div>
        <h1>Error</h1>
        <p>{error.message}</p>
        <p>The stack trace is:</p>
        <pre>{error.stack}</pre>
      </div>
    );
  } else {
    return <h1>Unknown Error</h1>;
  }
}