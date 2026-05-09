@module("../styles/main.css?url")
external mainCss: string = "default"

@react.component
let default = () => {
  <html lang="en">
    <head>
      <link rel="stylesheet" href={mainCss} />
      <ReactRouter.Links />
      <ReactRouter.Meta />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <meta charSet="UTF-8" />
      <title> {React.string("ReScript Guide")} </title>
    </head>
    <body>
      <ReactRouter.Outlet />
      <ReactRouter.ScrollRestoration />
      <ReactRouter.Scripts />
    </body>
  </html>
}
