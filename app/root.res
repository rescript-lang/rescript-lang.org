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
  import typescript from 'highlight.js/lib/languages/typescript';
  import json from 'highlight.js/lib/languages/json';
  import text from 'highlight.js/lib/languages/plaintext';
  import html from 'highlight.js/lib/languages/xml';
  import toml from 'highlight.js/lib/languages/ini';
  import rescript from 'highlightjs-rescript';

  hljs.registerLanguage('rescript', rescript)
  hljs.registerLanguage('javascript', javascript)
  hljs.registerLanguage('css', css)
  hljs.registerLanguage('ts', typescript)
  hljs.registerLanguage('sh', bash)
  hljs.registerLanguage('bash', bash)
  hljs.registerLanguage('toml', toml)
  hljs.registerLanguage('json', json)
  hljs.registerLanguage('text', text)
  hljs.registerLanguage('html', html)
  hljs.registerLanguage('diff', diff)
  hljs.registerLanguage('typescript', typescript)
`)

open ReactRouter

@react.component
let default = () => {
  let {pathname} = ReactRouter.useLocation()
  let (isOverlayOpen, setOverlayOpen) = React.useState(_ => false)
  let (isScrollLockEnabled, setIsScrollLockEnabled) = React.useState(_ => false)

  React.useEffect(() => {
    // When the path changes close the sidebar and disable scroll lock
    setOverlayOpen(_ => false)
    setIsScrollLockEnabled(_ => false)
    None
  }, [pathname])

  <html>
    <head>
      <style> {React.string("html {opacity:0;}")} </style>
      <link rel="preload" href={mainCss} as_="style" />
      <link rel="stylesheet" href={mainCss} />
      <link rel="stylesheet" href={hljsCss} />
      <link rel="stylesheet" href={utilsCss} />
      <link rel="icon" href="/favicon.ico" />
      <Links />
      <Meta />
      <meta
        name="viewport"
        content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, minimal-ui"
      />
      <meta charSet="UTF-8" />
    </head>
    <body className={isScrollLockEnabled ? "overflow-hidden" : ""}>
      <ScrollLockContext.Provider lockState=(isScrollLockEnabled, setIsScrollLockEnabled)>
        <EnableCollapsibleNavbar isEnabled={!isOverlayOpen}>
          <Navigation isOverlayOpen setOverlayOpen />
          <Outlet />
          <ScrollRestoration />
          <Scripts />
        </EnableCollapsibleNavbar>
      </ScrollLockContext.Provider>
    </body>
  </html>
}
