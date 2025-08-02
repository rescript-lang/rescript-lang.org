module ReactServer = {
  type rscPayload = {root: promise<Jsx.element>}

  @module("@vitejs/plugin-rsc/rsc")
  external renderToReadableStream: rscPayload => WebAPI.FileAPI.readableStream<'a> =
    "renderToReadableStream"
}

module ReactSSR = {
  type t<'a> = {root: React.component<'a>}

  @module("@vitejs/plugin-rsc/ssr")
  external createFromReadableStream: WebAPI.FileAPI.readableStream<'a> => promise<t<'a>> =
    "createFromReadableStream"

  type renderToReadableStreamOptions<'a> = {bootstrapScriptContent: 'a}

  @module("react-dom/server.edge")
  external renderToReadableStream: (
    'a,
    renderToReadableStreamOptions<'a>,
  ) => WebAPI.FileAPI.readableStream<'b> = "renderToReadableStream"

  @module("react")
  external use: promise<'a> => t<'a> = "use"

  external allReady: promise<bool> = "allReady"
}

module ImportMeta = {
  type ssr<'a> = {
    renderHtml: WebAPI.FileAPI.readableStream<'a> => promise<WebAPI.FileAPI.readableStream<'a>>,
  }

  external loadModule: (string, string) => promise<ssr<'a>> = "import.meta.viteRsc.loadModule"

  external loadBootstrapScriptContent: string => 'a =
    "import.meta.viteRsc.loadBootstrapScriptContent"
}
