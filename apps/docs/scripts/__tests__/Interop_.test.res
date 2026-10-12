open ScriptTest

@module("react-dom/server") external renderHtml: React.element => string = "renderToStaticMarkup"

test("MDX list items preserve paragraph and nested list structure", async () => {
  let html = renderHtml(
    <Markdown.Li>
      <Markdown.P> {React.string("Parent")} </Markdown.P>
      <Markdown.Ol>
        <Markdown.Li> {React.string("Child")} </Markdown.Li>
      </Markdown.Ol>
    </Markdown.Li>,
  )
  expect(html)->toContain("Parent</p><ol")
  expect(html->String.includes("<p><p"))->toBe(false)
  expect(renderHtml(<Markdown.Li> {React.null} </Markdown.Li>))->toContain("</li>")
})

test(
  "MDX code tabs read code, language, labels and line metadata from React children",
  async () => {
    HighlightLanguages.defaultInstance->ContentHighlighting.register
    let html = renderHtml(
      <ReactRouter.MemoryRouter>
        <Markdown.CodeTab labels=["Source", "Output"]>
          <pre>
            <Markdown.Code className="language-rescript" metastring=Some("{2}")>
              {React.string("let a = 1\nlet b = 2")}
            </Markdown.Code>
          </pre>
          <pre>
            <Markdown.Code className="language-javascript" metastring=None>
              {React.string("const a = 1;")}
            </Markdown.Code>
          </pre>
        </Markdown.CodeTab>
      </ReactRouter.MemoryRouter>,
    )
    expect(html)->toContain("Source")
    expect(html)->toContain("Output")
    expect(html)->toContain("lang-rescript")
    expect(html)->toContain("opacity-50")
    expect(html)->toContain("let")
    expect(html->String.replaceAllRegExp(/<[^>]*>/g, ""))->toContain("let b = 2")
  },
)

test("URL boxes preserve their first paragraph, following content and destination", async () => {
  let html = renderHtml(
    <ReactRouter.MemoryRouter>
      <Markdown.UrlBox text="Read more" href="/docs/manual/introduction">
        <p> {React.string("First paragraph")} </p>
        <p> {React.string("Second paragraph")} </p>
      </Markdown.UrlBox>
    </ReactRouter.MemoryRouter>,
  )
  expect(html)->toContain("First paragraph")
  expect(html)->toContain("Second paragraph")
  expect(html)->toContain("Read more")
  expect(html)->toContain("href=\"/docs/manual/introduction\"")
  expect(html->String.includes("<p><p"))->toBe(false)
})

test("meta tag extraction visits exactly the available HTML elements", async () => {
  let html = `<meta name="og:title" content="Title"><meta property="og:description" content="Description"><meta itemprop="og:image" content="/image.png">`
  let result = await MetaTagsApi.extractMetaTags(`data:text/html,${encodeURIComponent(html)}`)
  expect(result)->toStrictEqual(
    Some({
      MetaTagsApi.title: Some("Title"),
      description: Some("Description"),
      image: Some("/image.png"),
    }),
  )
  let empty = await MetaTagsApi.extractMetaTags("data:text/html,<title>No meta</title>")
  expect(empty)->toStrictEqual(Some({MetaTagsApi.title: None, description: None, image: None}))
})

test("typed string helpers preserve empty strings and repeated hyphen behavior", async () => {
  expect(Util.String.camelCase("hello--world-42-next"))->toBe("hello-World-42Next")
  expect(Util.String.capitalize(""))->toBe("")
  expect(Util.String.capitalize("hello"))->toBe("Hello")
})
