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

test("desktop blog article renders header, author, date, and body", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-article-wrapper">
        <BlogArticle frontmatter=mockFrontmatter isArchived=false path="/blog/test-article">
          <div> {React.string("This is the blog post body content for testing.")} </div>
        </BlogArticle>
      </div>
    </BrowserRouter>,
  )

  let title = await screen->getByText("Test Blog Post Title")
  await element(title)->toBeVisible

  let authorName = await screen->getByText("Test Author")
  await element(authorName)->toBeVisible

  let description = await screen->getByText("A short description of the blog post for testing.")
  await element(description)->toBeVisible

  let wrapper = await screen->getByTestId("blog-article-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-blog-article")
})

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

test("desktop archived blog article shows warning banner", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-article-wrapper">
        <BlogArticle frontmatter=mockFrontmatter isArchived=true path="/blog/test-article">
          <div> {React.string("This is the blog post body content for testing.")} </div>
        </BlogArticle>
      </div>
    </BrowserRouter>,
  )

  let important = await screen->getByText("Important:")
  await element(important)->toBeVisible

  let wrapper = await screen->getByTestId("blog-article-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-blog-article-archived")
})

test("mobile blog article", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-article-wrapper">
        <BlogArticle frontmatter=mockFrontmatter isArchived=false path="/blog/test-article">
          <div> {React.string("This is the blog post body content for testing.")} </div>
        </BlogArticle>
      </div>
    </BrowserRouter>,
  )

  let title = await screen->getByText("Test Blog Post Title")
  await element(title)->toBeVisible

  let authorName = await screen->getByText("Test Author")
  await element(authorName)->toBeVisible

  let description = await screen->getByText("A short description of the blog post for testing.")
  await element(description)->toBeVisible

  let wrapper = await screen->getByTestId("blog-article-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-blog-article")
})

let mockCoAuthor: BlogFrontmatter.author = {
  username: "co-author",
  fullname: "Co Author",
  role: "Contributor",
  imgUrl: "https://rescript-lang.org/brand/rescript-brandmark.svg",
  social: Bluesky("coauthor.bsky.social"),
}

let mockFrontmatterWithCoAuthors: BlogFrontmatter.t = {
  author: mockAuthor,
  co_authors: [mockCoAuthor],
  date: DateStr.fromString("2025-03-20"),
  previewImg: Nullable.null,
  articleImg: Nullable.null,
  title: "Collaborative Blog Post",
  badge: Nullable.Value(Release),
  description: Nullable.Value("A post written by multiple authors."),
}

test("desktop blog article with co-authors shows all authors", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-article-wrapper">
        <BlogArticle
          frontmatter=mockFrontmatterWithCoAuthors isArchived=false path="/blog/collab-post"
        >
          <div> {React.string("Collaborative content.")} </div>
        </BlogArticle>
      </div>
    </BrowserRouter>,
  )

  let mainAuthor = await screen->getByText("Test Author")
  await element(mainAuthor)->toBeVisible

  let coAuthor = await screen->getByText("Co Author")
  await element(coAuthor)->toBeVisible

  let wrapper = await screen->getByTestId("blog-article-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-blog-article-coauthors")
})

let mockFrontmatterWithArticleImg: BlogFrontmatter.t = {
  author: mockAuthor,
  co_authors: [],
  date: DateStr.fromString("2025-06-01"),
  previewImg: Nullable.null,
  articleImg: Nullable.Value("/brand/rescript-brandmark.svg"),
  title: "Blog Post With Article Image",
  badge: Nullable.Value(Release),
  description: Nullable.Value("A post with an article image."),
}

test("desktop blog article with article image shows image", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-article-wrapper">
        <BlogArticle
          frontmatter=mockFrontmatterWithArticleImg isArchived=false path="/blog/image-post"
        >
          <div> {React.string("Content below the article image.")} </div>
        </BlogArticle>
      </div>
    </BrowserRouter>,
  )

  let title = await screen->getByText("Blog Post With Article Image")
  await element(title)->toBeVisible

  let wrapper = await screen->getByTestId("blog-article-wrapper")
  await waitForImages("[data-testid='blog-article-wrapper']")
  await element(wrapper)->toMatchScreenshot("desktop-blog-article-with-image")
})

let mockFrontmatterNoDescription: BlogFrontmatter.t = {
  author: mockAuthor,
  co_authors: [],
  date: DateStr.fromString("2025-02-10"),
  previewImg: Nullable.null,
  articleImg: Nullable.null,
  title: "Blog Post Without Description",
  badge: Nullable.null,
  description: Nullable.null,
}

test("desktop blog article without description", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-article-wrapper">
        <BlogArticle frontmatter=mockFrontmatterNoDescription isArchived=false path="/blog/no-desc">
          <div> {React.string("Content without a description above.")} </div>
        </BlogArticle>
      </div>
    </BrowserRouter>,
  )

  let title = await screen->getByText("Blog Post Without Description")
  await element(title)->toBeVisible

  let wrapper = await screen->getByTestId("blog-article-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-blog-article-no-description")
})
