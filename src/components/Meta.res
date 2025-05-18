module Head = Next.Head

/*
    canonical: Set a canonical URL pointing to the original content.
 */
@react.component
let make = (
  ~siteName="ReScript Documentation",
  ~keywords: array<string>=[],
  ~description="The ReScript language and ecosystem docs",
  ~canonical=?,
  ~title=?,
  ~ogLocale="en_US",
  ~ogSiteName=?,
  ~ogDescription=description,
  ~ogTitle=?,
  ~ogImage="/static/Art-3-rescript-launch.jpg",
  ~version: option<Url.version>=?,
) => {
  let ogImage = "https://rescript-lang.org" ++ ogImage

  let title = switch title {
  | None
  | Some("") => siteName
  | Some(title) => title
  }

  let ogSiteName = switch ogSiteName {
  | Some(ogSiteName) => ogSiteName
  | None => siteName
  }

  let ogTitle = switch ogTitle {
  | Some(ogTitle) => ogTitle
  | None => title
  }

  <Head>
    <title key="title"> {React.string(title)} </title>
    <meta charSet="utf-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, minimal-ui"
    />
    <meta key="description" name="description" content=description />
    <meta key="keywords" name="keywords" content={Array.join(keywords, ",")} />
    {switch canonical {
    | Some(href) => <link key="canonical" href rel="canonical" />
    | None => React.null
    }}
    <link rel="apple-touch-icon" sizes="180x180" href="/static/favicon/apple-touch-icon.png" />
    <link rel="icon" type_="image/png" sizes="32x32" href="/static/favicon/favicon-32x32.png" />
    <link rel="icon" type_="image/png" sizes="16x16" href="/static/favicon/favicon-16x16.png" />
    <link rel="manifest" href="/static/favicon/site.webmanifest" />
    /* OG link preview meta data */
    <meta key="og:site_name" property="og:site_name" content=ogSiteName />
    <meta key="og:locale" property="og:locale" content=ogLocale />
    <meta key="og:title" property="og:title" content=ogTitle />
    <meta key="og:description" property="og:description" content=ogDescription />
    <meta key="og:image" property="og:image" content=ogImage />

    /* Twitter Meta */
    <meta key="twitter:title" name="twitter:title" content=title />
    <meta key="twitter:description" name="twitter:description" content=description />
    <meta key="twitter:site" name="twitter:site" content="@rescriptlang" />
    <meta key="twitter:image" property="og:image" content=ogImage />
    <meta key="twitter:creator" name="twitter:creator" content="@ReScriptAssoc" />
    <meta key="twitter:card" name="twitter:card" content="summary_large_image" />
    <link rel="alternate" type_="application/rss+xml" title="ReScript Blog" href="/blog/feed.xml" />
    // Docsearch meta tags
    <meta
      name="docsearch:version"
      content={switch version {
      | Some(Version(v)) => v
      | _ => Constants.versions.latest
      }}
    />
  </Head>
}
