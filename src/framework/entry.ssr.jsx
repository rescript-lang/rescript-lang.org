import * as ReactClient from '@vitejs/plugin-rsc/ssr'
import React from 'react'
import * as ReactDomServer from 'react-dom/server.edge'
import { injectRSCPayload } from 'rsc-html-stream/server'


export async function renderHtml(rscStream) {
  console.log("[ssr]: renderHtml")
  const [rscStream1, rscStream2] = rscStream.tee()

  let payload
  function SsrRoot() {
    payload ??= ReactClient.createFromReadableStream(rscStream1)
    const root = React.use(payload).root
    return root
  }

  const bootstrapScriptContent =
    await import.meta.viteRsc.loadBootstrapScriptContent('index')

  const htmlStream = await ReactDomServer.renderToReadableStream(<SsrRoot />, {
    bootstrapScriptContent,
  })
  // for SSG
  await htmlStream.allReady

  let responseStream = htmlStream
  responseStream = responseStream.pipeThrough(injectRSCPayload(rscStream2))
  return responseStream
}