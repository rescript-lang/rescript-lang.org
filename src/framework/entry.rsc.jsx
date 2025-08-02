import * as ReactServer from '@vitejs/plugin-rsc/rsc'
import { Root, getStaticPaths } from '../root.jsx'
import { RSC_POSTFIX } from './shared.mjs'

export { getStaticPaths }

export default async function handler(request) {
  let url = new URL(request.url)
  let isRscRequest = false
  if (url.pathname.endsWith(RSC_POSTFIX)) {
    isRscRequest = true
    url.pathname = url.pathname.slice(0, -RSC_POSTFIX.length)
  }

  const rscPayload = { root: <Root url={url} /> }
  const rscStream = ReactServer.renderToReadableStream(rscPayload)

  if (isRscRequest) {
    return new Response(rscStream, {
      headers: {
        'content-type': 'text/x-component;charset=utf-8',
        vary: 'accept',
      },
    })
  }

  const ssr = await import.meta.viteRsc.loadModule('ssr', 'index')
  const htmlStream = await ssr.renderHtml(rscStream)

  return new Response(htmlStream, {
    headers: {
      'content-type': 'text/html;charset=utf-8',
      vary: 'accept',
    },
  })
}