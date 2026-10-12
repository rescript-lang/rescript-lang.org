open ReactRouter
open Vitest

@get external textContent: WebAPI.DOMAPI.element => string = "textContent"

let mockAuthor: BlogFrontmatter.author = {
  username: "test-author",
  fullname: "Test Author",
  role: "Developer",
  imgUrl: "https://rescript-lang.org/brand/rescript-brandmark.svg",
  social: X("testauthor"),
}

let mockFrontmatter: BlogFrontmatter.t = {
  author: mockAuthor,
  co_authors: [],
  date: DateStr.fromString("2025-01-15"),
  previewImg: Nullable.null,
  articleImg: Nullable.null,
  title: "Test Blog Post Title",
  badge: Nullable.null,
  description: Nullable.Value("A short description of the blog post for testing."),
}

test("blog article marks body content for DocSearch crawling", async () => {
  await viewport(1440, 900)

  let _screen = await render(
    <BrowserRouter>
      <BlogArticle frontmatter=mockFrontmatter isArchived=false path="/blog/test-article">
        <p> {React.string("This is the blog post body content for testing.")} </p>
      </BlogArticle>
    </BrowserRouter>,
  )

  switch document->WebAPI.Document.querySelector("article.DocSearch-content") {
  | Value(_) => ()
  | Null => failwith("expected blog article body to be marked as DocSearch content")
  }

  let lvl0 = switch document->WebAPI.Document.querySelector("article .DocSearch-lvl0") {
  | Value(element) => element
  | Null => failwith("expected blog article to render a DocSearch lvl0 marker")
  }

  expect(lvl0->textContent)->toBe("Blog")
})
