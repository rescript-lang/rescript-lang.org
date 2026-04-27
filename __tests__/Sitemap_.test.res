open Vitest

test("renders sorted unique sitemap URLs with a normalized base URL", async () => {
  let xml = Sitemap.render(
    ~baseUrl="https://preview.example.com/",
    ["/docs/manual/introduction", "blog", "/", "/docs/manual/introduction"],
  )

  expect(xml)->toBe(`<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://preview.example.com/</loc>
  </url>
  <url>
    <loc>https://preview.example.com/blog/</loc>
  </url>
  <url>
    <loc>https://preview.example.com/docs/manual/introduction/</loc>
  </url>
</urlset>
`)
})
