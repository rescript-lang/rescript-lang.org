open WebAPI

%%raw("import React from 'react'")

let loadGoogleFont = async (family: string) => {
  let url = `https://fonts.googleapis.com/css2?family=${family}`
  let css = await (await fetch(url))->Response.text

  // this function should fail if we can't load the font
  let resource =
    css->String.match(/src: url\((.+)\) format\('(opentype|truetype)'\)/)->Option.getOrThrow
  let response = await fetch(resource[1]->Option.getOrThrow->Option.getOrThrow)
  await response->Response.arrayBuffer
}

type context = {request: FetchAPI.request, params: {path: array<string>}}

let textResponse = (~status, message) => Response.fromString(message, ~init={status: status})

let parseUrl = url => {
  try {
    Some(URL.make(~url))
  } catch {
  | _ => None
  }
}

let normalizeText = value => value->String.trim->String.replaceAllRegExp(/\s+/g, " ")

let nonEmptyText = value => {
  let value = value->normalizeText
  value == "" ? None : Some(value)
}

let prefer = (primary, fallback) =>
  switch primary {
  | Some(_) => primary
  | None => fallback
  }

let firstCapture = (value, regexp) => {
  switch regexp->RegExp.exec(value) {
  | Some(result) =>
    let matches = result->RegExp.Result.matches
    switch matches[0] {
    | Some(Some(match)) => match->nonEmptyText
    | Some(None) | None => None
    }
  | None => None
  }
}

let decodeHtmlEntities = value =>
  value
  ->String.replaceAll("&amp;", "&")
  ->String.replaceAll("&quot;", "\"")
  ->String.replaceAll("&#39;", "'")
  ->String.replaceAll("&apos;", "'")
  ->String.replaceAll("&lt;", "<")
  ->String.replaceAll("&gt;", ">")

let extractMetaContent = (html, key) => {
  let escapedKey = key->RegExp.escape
  let regexp = RegExp.fromString(
    `<meta\\b(?=[^>]*(?:property|name)\\s*=\\s*["']${escapedKey}["'])(?=[^>]*content\\s*=\\s*["']([^"']*)["'])[^>]*>`,
    ~flags="i",
  )

  html->firstCapture(regexp)->Option.map(decodeHtmlEntities)
}

let extractTitle = html =>
  html
  ->firstCapture(RegExp.fromString("<title\\b[^>]*>([\\s\\S]*?)</title>", ~flags="i"))
  ->Option.map(decodeHtmlEntities)

let extractDocumentText = async response => {
  let html = await response->Response.text
  let title =
    prefer(
      html->extractMetaContent("og:title"),
      prefer(html->extractMetaContent("twitter:title"), html->extractTitle),
    )->Option.getOr("ReScript")
  let description =
    prefer(
      html->extractMetaContent("og:description"),
      prefer(
        html->extractMetaContent("twitter:description"),
        html->extractMetaContent("description"),
      ),
    )->Option.getOr("ReScript")

  (title, description)
}

let splitPreviewText = (~title, ~description) => {
  let titleSegments = title->String.split("|")
  let descriptionSegments = description->String.split(".")

  let (subTitle, description) = switch titleSegments[1] {
  | Some(subTitle) => (Some(subTitle->normalizeText), description)
  | None =>
    switch descriptionSegments[1] {
    | Some(description) => (descriptionSegments[0]->Option.map(normalizeText), description)
    | None => (None, description)
    }
  }

  (titleSegments[0]->Option.getOr("")->normalizeText, subTitle, description->normalizeText)
}

let requestedUrl = (~requestUrl: URLAPI.url, ~params) => {
  switch requestUrl.searchParams->URLSearchParams.get("url")->Nullable.make->Nullable.toOption {
  | Some(url) => Some(url)
  | None => params.path[0]->Option.map(decodeURIComponent)
  }
}

let isHtmlResponse = (response: FetchAPI.response) =>
  response.headers
  ->Headers.get("content-type")
  ->Null.toOption
  ->Option.mapOr(false, contentType =>
    contentType->String.toLowerCase->String.includes("text/html")
  )

let renderImage = async (~requestUrl: URLAPI.url, ~targetUrl: URLAPI.url) => {
  if targetUrl.origin != requestUrl.origin {
    textResponse(~status=400, "Open Graph image URL must be same-origin")
  } else if targetUrl.pathname->String.startsWith("/ogimage/") {
    textResponse(~status=400, "Open Graph image URL cannot point at the image endpoint")
  } else {
    let pageResponse = try {
      Some(await fetch(targetUrl.href, ~init={redirect: FetchAPI.Error}))
    } catch {
    | _ => None
    }

    switch pageResponse {
    | None => textResponse(~status=502, "Could not fetch Open Graph image URL")
    | Some(pageResponse) if !pageResponse.ok =>
      textResponse(~status=pageResponse.status, "Could not fetch Open Graph image URL")
    | Some(pageResponse) =>
      switch pageResponse.url->parseUrl {
      | Some(responseUrl) if responseUrl.origin != requestUrl.origin =>
        textResponse(~status=400, "Fetched Open Graph image URL must be same-origin")
      | Some(_) | None =>
        if !(pageResponse->isHtmlResponse) {
          textResponse(~status=415, "Open Graph image URL must return an HTML document")
        } else {
          let (title, description) = await pageResponse->extractDocumentText
          let (title, subTitle, description) = splitPreviewText(~title, ~description)

          await Cloudflare.imageResponse(
            <div
              style={{
                width: "1200px",
                height: "630px",
                background: "#0B0D22",
                backgroundImage: "linear-gradient(45deg, #0B0D22 70%, #14162c)",
                color: "#efefef",
                display: "flex",
                flexDirection: "column",
                alignItems: "flex-start",
                textAlign: "left",
                position: "relative",
                padding: "0 60px",
                boxSizing: "border-box",
              }}
            >
              <img
                src="https://rescript-lang.org/brand/rescript-logo.svg"
                style={{
                  maxWidth: "300px",
                  objectFit: "contain",
                  marginBottom: "10px",
                }}
              />
              <h1
                style={{
                  fontSize: "64px",
                  fontWeight: "600",
                  marginBottom: "20px",
                  maxWidth: "996px",
                  fontFamily: "heading",
                  textWrap: "balance",
                }}
              >
                {React.string(title)}
              </h1>
              {switch subTitle {
              | Some(subTitle) =>
                <h2
                  style={{
                    fontSize: "40px",
                    fontWeight: "600",
                    marginBottom: "20px",
                    maxWidth: "996px",
                    fontFamily: "heading",
                    textWrap: "balance",
                  }}
                >
                  {React.string(subTitle)}
                </h2>
              | None => React.null
              }}
              <hr
                style={{
                  borderTop: "2px solid #efefef",
                  width: "100%",
                }}
              />
              <p
                style={{
                  fontFamily: "text",
                  fontSize: "28px",
                  lineHeight: "36px",
                  opacity: "0.9",
                  // extra space since X wants to overlay the text
                  maxWidth: "900px",
                  maxHeight: "108px",
                  textWrap: "pretty",
                }}
              >
                {React.string(description)}
              </p>
            </div>,
            {
              height: 630,
              width: 1200,
              fonts: [
                {
                  data: await loadGoogleFont("Inter:opsz,wght@14..32,600&display=swap"),
                  name: "heading",
                  style: #normal,
                  weight: 600,
                },
                {
                  data: await loadGoogleFont("Inter:opsz,wght@14..32,400&display=swap"),
                  name: "text",
                  style: #normal,
                  weight: 400,
                },
              ],
            },
          )
        }
      }
    }
  }
}

let onRequest = async ({request, params}: context) => {
  let requestUrl = URL.make(~url=request.url)

  switch requestedUrl(~requestUrl, ~params)->Option.flatMap(parseUrl) {
  | None => textResponse(~status=400, "Missing or invalid url")
  | Some(targetUrl) => await renderImage(~requestUrl, ~targetUrl)
  }
}
