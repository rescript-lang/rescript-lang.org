@module("../styles/main.css?url")
external mainCss: string = "default"

@module("../styles/_hljs.css?url")
external hljsCss: string = "default"

open ReactRouter

@react.component
let default = () => {
  <html lang="en">
    <head>
      {CypressBootstrap.element()}
      <style> {React.string("html {opacity:0;}")} </style>
      <link rel="preload" href={mainCss} as_="style" />
      <link rel="stylesheet" href={mainCss} />
      <link rel="stylesheet" href={hljsCss} />
      <link rel="icon" href="/favicon.ico" />
      <Links />
      <ReactRouter.Meta />
      <meta
        name="viewport"
        content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, minimal-ui"
      />
      <meta charSet="UTF-8" />
    </head>
    <body>
      <NavbarPrimary />
      <Outlet />
      <ScrollRestoration />
      <Scripts />
    </body>
  </html>
}
