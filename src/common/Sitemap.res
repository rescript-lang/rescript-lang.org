let defaultBaseUrl = "https://rescript-lang.org"

let normalizeBaseUrl = baseUrl => {
  let trimmed = baseUrl->String.trim

  let baseUrl = if trimmed === "" {
    defaultBaseUrl
  } else {
    trimmed
  }

  if baseUrl->String.endsWith("/") {
    baseUrl->String.slice(~start=0, ~end=baseUrl->String.length - 1)
  } else {
    baseUrl
  }
}

let normalizePath = path => {
  let trimmed = path->String.trim

  if trimmed === "" || trimmed === "/" {
    "/"
  } else if trimmed->String.startsWith("/") {
    trimmed
  } else {
    "/" ++ trimmed
  }
}

let escapeXml = value =>
  value
  ->String.replaceAll("&", "&amp;")
  ->String.replaceAll("<", "&lt;")
  ->String.replaceAll(">", "&gt;")
  ->String.replaceAll("\"", "&quot;")
  ->String.replaceAll("'", "&apos;")

let normalizePaths = paths =>
  paths
  ->Array.map(normalizePath)
  ->Array.toSorted(String.compare)
  ->Array.reduce([], (acc, path) => {
    if acc->Array.includes(path) {
      acc
    } else {
      acc->Array.push(path)
      acc
    }
  })

let renderUrl = (~baseUrl, path) => {
  let loc = baseUrl ++ path

  `  <url>
    <loc>${loc->escapeXml}</loc>
  </url>`
}

let render = (~baseUrl, paths) => {
  let baseUrl = normalizeBaseUrl(baseUrl)
  let urls =
    paths
    ->normalizePaths
    ->Array.map(path => renderUrl(~baseUrl, path))
    ->Array.join("\n")

  `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>
`
}
