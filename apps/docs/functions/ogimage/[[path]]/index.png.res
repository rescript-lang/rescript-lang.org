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

let onRequest = async ({params}: context) => {
  let title = params.path[0]->Option.getOr("ReScript")->decodeURIComponent
  let description = params.path[1]->Option.getOr("ReScript")->decodeURIComponent

  // we want to split the title if it contains a |
  let (title, subTitle, description) = {
    let titleSegments = title->String.split("|")
    // if the description contains a `.` we want to split it up and use the first sentence as the subTitle
    let descriptionSegments = description->String.split(".")

    let (subTitle, description) = switch titleSegments[1] {
    | Some(subTitle) => (Some(subTitle), description)
    | None =>
      switch descriptionSegments[1] {
      | Some(description) => (descriptionSegments[0], description)
      | None => (None, description)
      }
    }

    (titleSegments[0]->Option.getOr(""), subTitle, description)
  }

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
