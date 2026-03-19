open ReactRouter
open Vitest

let mockAuthor: BlogFrontmatter.author = {
  username: "rescript-team",
  fullname: "ReScript Team",
  role: "Core Development",
  imgUrl: "https://rescript-lang.org/brand/rescript-brandmark.svg",
  social: X("rescriptlang"),
}

let mockPosts: array<BlogApi.post> = [
  {
    path: "blog/release-12-0-0",
    archived: false,
    frontmatter: {
      author: mockAuthor,
      co_authors: [],
      date: DateStr.fromString("2025-11-25"),
      previewImg: Nullable.null,
      articleImg: Nullable.null,
      title: "Announcing ReScript 12",
      badge: Nullable.Value(Release),
      description: Nullable.Value("ReScript 12 arrives with a redesigned build toolchain."),
    },
  },
  {
    path: "blog/release-11-1-0",
    archived: false,
    frontmatter: {
      author: mockAuthor,
      co_authors: [],
      date: DateStr.fromString("2024-06-15"),
      previewImg: Nullable.null,
      articleImg: Nullable.null,
      title: "ReScript 11.1",
      badge: Nullable.Value(Release),
      description: Nullable.Value("Tagged template literals, import attributes, and more."),
    },
  },
  {
    path: "blog/improving-interop",
    archived: false,
    frontmatter: {
      author: mockAuthor,
      co_authors: [],
      date: DateStr.fromString("2024-03-01"),
      previewImg: Nullable.null,
      articleImg: Nullable.null,
      title: "Improving Interop",
      badge: Nullable.null,
      description: Nullable.Value("Better JavaScript interoperability in ReScript."),
    },
  },
]

test("desktop blog index shows featured post and cards", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-wrapper">
        <Blog posts=mockPosts category=All />
      </div>
    </BrowserRouter>,
  )

  let featured = await screen->getByText("Announcing ReScript 12")
  await element(featured)->toBeVisible

  let card1 = await screen->getByText("ReScript 11.1")
  await element(card1)->toBeVisible

  let card2 = await screen->getByText("Improving Interop")
  await element(card2)->toBeVisible

  let wrapper = await screen->getByTestId("blog-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-blog-index")
})

test("desktop blog shows category selector", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-wrapper">
        <Blog posts=mockPosts category=All />
      </div>
    </BrowserRouter>,
  )

  let allTab = await screen->getByText("All")
  await element(allTab)->toBeVisible

  let archivedTab = await screen->getByText("Archived")
  await element(archivedTab)->toBeVisible

  let wrapper = await screen->getByTestId("blog-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-blog-category-selector")
})

test("mobile blog index", async () => {
  await viewport(600, 1200)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-wrapper">
        <Blog posts=mockPosts category=All />
      </div>
    </BrowserRouter>,
  )

  let featured = await screen->getByText("Announcing ReScript 12")
  await element(featured)->toBeVisible

  let wrapper = await screen->getByTestId("blog-wrapper")
  await element(wrapper)->toMatchScreenshot("mobile-blog-index")
})

test("blog shows empty state when no posts", async () => {
  await viewport(1440, 900)

  let screen = await render(
    <BrowserRouter>
      <div dataTestId="blog-empty-wrapper">
        <Blog posts=[] category=All />
      </div>
    </BrowserRouter>,
  )

  let emptyMsg = await screen->getByText("Blog not yet available")
  await element(emptyMsg)->toBeVisible

  let wrapper = await screen->getByTestId("blog-empty-wrapper")
  await element(wrapper)->toMatchScreenshot("desktop-blog-empty")
})
