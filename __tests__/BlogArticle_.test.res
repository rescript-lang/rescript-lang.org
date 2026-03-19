open ReactRouter
open Vitest

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
