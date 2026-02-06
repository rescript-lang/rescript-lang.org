open WebAPI

%%raw("import React from 'react'")

let loadGoogleFont = async (family: string, text: string) => {
  let url = `https://fonts.googleapis.com/css2?family=${family}&text=${encodeURIComponent(text)}`
  let css = await (await fetch(url))->Response.text

  // this function should fail if we can't load the font
  let resource =
    css->String.match(/src: url\((.+)\) format\('(opentype|truetype)'\)/)->Option.getOrThrow
  let response = await fetch(resource[1]->Option.getOrThrow->Option.getOrThrow)
  await response->Response.arrayBuffer
}

type context = {request: FetchAPI.request}

let onRequest = async ({request}: context) => {
  let url = WebAPI.URL.make(~url=request.url)
  let title = url.searchParams->URLSearchParams.get("title")
  let descripton = url.searchParams->URLSearchParams.get("description")

  Cloudflare.imageResponse(
    <div
      style={{
        width: "1200px",
        height: "630px",
        background: "#0B0D22",
        backgroundImage: "linear-gradient(45deg, #0B0D22 70%, #14162c)",
        color: "#efefef",
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "flex-start",
        textAlign: "left",
        position: "relative",
        padding: "60px",
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
      <hr
        style={{
          borderTop: "2px solid #efefef",
          width: "100%",
        }}
      />
      <p
        style={{
          fontFamily: "text",
          fontSize: "32px",
          opacity: "0.9",
          maxWidth: "900px",
          textWrap: "balance",
        }}
      >
        {React.string(descripton)}
      </p>
    </div>,
    {
      height: 630,
      width: 1200,
      fonts: [
        {
          data: await loadGoogleFont("Inter:opsz,wght@14..32,600&display=swap", title),
          name: "heading",
          style: #normal,
          weight: 600,
        },
        {
          data: await loadGoogleFont("Inter:opsz,wght@14..32,400&display=swap", descripton),
          name: "text",
          style: #normal,
          weight: 600,
        },
      ],
    },
  )
}
