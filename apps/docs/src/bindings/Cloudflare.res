open WebAPI

type font = {
  name: string,
  data: ArrayBuffer.t,
  weight: int,
  style: [#normal | #italix],
}

type ogImageOptions = {
  width: int,
  height: int,
  fonts: array<font>,
}

type t = FetchAPI.response

@new @module("@cloudflare/pages-plugin-vercel-og/api")
external imageResponse: (Jsx.element, ogImageOptions) => promise<t> = "ImageResponse"

type htmlRewriter
type htmlRewriterElement
type htmlRewriterTextChunk = {text: string}
type htmlRewriterElementHandler = {element: htmlRewriterElement => unit}
type htmlRewriterTextHandler = {text: htmlRewriterTextChunk => unit}

@new external htmlRewriter: unit => htmlRewriter = "HTMLRewriter"
@send external onElement: (htmlRewriter, string, htmlRewriterElementHandler) => htmlRewriter = "on"
@send external onText: (htmlRewriter, string, htmlRewriterTextHandler) => htmlRewriter = "on"
@send external transform: (htmlRewriter, FetchAPI.response) => FetchAPI.response = "transform"
@send external getAttribute: (htmlRewriterElement, string) => null<string> = "getAttribute"
