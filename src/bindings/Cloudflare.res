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
  headers: {
    @as("Content-Type") contentType: string,
  },
}

type t

@new @module("@cloudflare/pages-plugin-vercel-og/api")
external imageResponse: (Jsx.element, ogImageOptions) => promise<t> = "ImageResponse"
