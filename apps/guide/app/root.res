@module("../styles/main.css?url")
external mainCss: string = "default"

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
      <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.avif" />
      <link rel="icon" type_="image/avif" sizes="32x32" href="/favicon-32x32.avif" />
      <link rel="icon" type_="image/avif" sizes="16x16" href="/favicon-16x16.avif" />
      <title> {React.string("ReScript Guide")} </title>
    </head>
    <body>
      <ReactRouter.Outlet />
      <ReactRouter.ScrollRestoration />
      <ReactRouter.Scripts />
    </body>
  </html>
}
