let downloadLink = ((label, href)) => {
  <a key=href className="text-fire hover:underline inline-flex items-center gap-1" href>
    {React.string(label)}
    <Icon.ExternalLink className="w-4 h-4" />
  </a>
}

let assetCard = (~title, ~description, ~image, ~imageClassName="", ~dark=false, ~downloads) => {
  let previewClassName = dark
    ? "bg-gray-90 border border-gray-20 rounded-lg p-8 flex min-h-48 items-center justify-center"
    : "bg-gray-5 border border-gray-10 rounded-lg p-8 flex min-h-48 items-center justify-center"

  <section className="border border-gray-10 rounded-lg bg-white p-6">
    <h2 className="font-bold text-24 mb-2"> {React.string(title)} </h2>
    <p className="body-md text-gray-70 mb-6"> {React.string(description)} </p>
    <div className=previewClassName>
      <img src=image className=imageClassName alt={title ++ " preview"} />
    </div>
    <div className="flex flex-wrap gap-x-4 gap-y-2 mt-5 text-16">
      {downloads->Array.map(download => downloadLink(download))->React.array}
    </div>
  </section>
}

let default = () => {
  <MainLayout>
    <Meta
      title="Brand Assets | ReScript"
      description="Download the official ReScript logo and brandmark assets."
      canonical="/brand"
    />
    <div className="max-w-740 w-full m-auto">
      <Markdown.H1> {React.string("Brand Assets")} </Markdown.H1>
      <p className="body-lg text-gray-70 mb-10">
        {React.string(
          "Official ReScript logo and brandmark assets for use in articles, talks, websites, and community projects.",
        )}
      </p>
      <div className="grid grid-cols-1 gap-8">
        {assetCard(
          ~title="Brandmark",
          ~description="The standalone ReScript symbol.",
          ~image="/brand/rescript-brandmark.svg",
          ~imageClassName="h-24 w-24",
          ~downloads=[
            ("SVG", "/brand/rescript-brandmark.svg"),
            ("AVIF", "/brand/rescript-brandmark.avif"),
          ],
        )}
        {assetCard(
          ~title="Logo",
          ~description="The primary ReScript logo with wordmark.",
          ~image="/brand/rescript-logo.svg",
          ~imageClassName="h-24",
          ~downloads=[("SVG", "/brand/rescript-logo.svg"), ("AVIF", "/brand/rescript-logo.avif")],
        )}
        {assetCard(
          ~title="Logo on Dark",
          ~description="The white ReScript logo for dark backgrounds.",
          ~image="/brand/rescript-logo-white.svg",
          ~imageClassName="h-24",
          ~dark=true,
          ~downloads=[
            ("SVG", "/brand/rescript-logo-white.svg"),
            ("AVIF", "/brand/rescript-logo-white.avif"),
          ],
        )}
      </div>
    </div>
  </MainLayout>
}
