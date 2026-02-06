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
  Console.log(title)
  Cloudflare.imageResponse(
    <div
      style={{
        width: "1200px",
        height: "630px",
        background: "linear-gradient(100deg,rgba(11, 13, 34, 1) 0%, rgba(20, 22, 24, 1) 100%)",
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
        }}
      >
        {React.string(title)}
      </h1>
      <p
        style={{
          fontFamily: "text",
          fontSize: "32px",
          opacity: "0.9",
          maxWidth: "900px",
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
