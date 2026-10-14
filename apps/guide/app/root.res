@module("../styles/main.css?url")
external mainCss: string = "default"

// Share the official icons while keeping the guide's own public directory.
@module("../../docs/public/favicon/apple-touch-icon.avif?url&no-inline")
external appleTouchIcon: string = "default"

@module("../../docs/public/favicon/favicon-32x32.avif?url&no-inline")
external favicon32: string = "default"

@module("../../docs/public/favicon/favicon-16x16.avif?url&no-inline")
external favicon16: string = "default"

@react.component
let default = () => {
  <html lang="en">
    <head>
      <link rel="stylesheet" href={mainCss} />
      <ReactRouter.Links />
      <ReactRouter.Meta />
      <meta charSet="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <meta name="application-name" content="ReScript Guide" />
      <meta name="description" content="An interactive guide to learning ReScript." />
      <meta name="theme-color" content="#f6f4ef" />
      <link rel="apple-touch-icon" sizes="180x180" href=appleTouchIcon />
      <link rel="icon" type_="image/avif" sizes="32x32" href=favicon32 />
      <link rel="icon" type_="image/avif" sizes="16x16" href=favicon16 />
      <title> {React.string("ReScript Guide")} </title>
    </head>
    <body>
      <ReactRouter.Outlet />
      <ReactRouter.ScrollRestoration />
      <ReactRouter.Scripts />
    </body>
  </html>
}
