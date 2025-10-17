/*
      This module is responsible for statically prerendering each individual blog post.
 General concepts:
      -----------------------
      - We use webpack's "require" mechanic to reuse the MDX pipeline for rendering
      - Frontmatter is being parsed and attached as an attribute to the resulting component function via plugins/mdx-loader
      - We generate a list of static paths for each blog post via the BlogApi module (using fs)
      - The contents of this file is being reexported by /pages/blog/[slug].js


      A Note on Performance:
      -----------------------
      Luckily, since pages are prerendered, we don't need to worry about
      increased bundle sizes due to the `require` with path interpolation. It
      might cause longer builds though, so we might need to refactor as soon as
      builds are taking too long.  I think we will be fine for now.
  Link to NextJS discussion: https://github.com/zeit/next.js/discussions/11728#discussioncomment-3501
 */

let middleDotSpacer = " " ++ (String.fromCharCode(183) ++ " ")

module Params = {
  type t = {slug: string}
}

type props = {
  children: React.element,
  isArchived: bool,
  path: string,
  frontmatter: BlogFrontmatter.t,
}

module Line = {
  @react.component
  let make = () => <div className="block border-t border-gray-20" />
}

module AuthorBox = {
  @react.component
  let make = (~author: BlogFrontmatter.author) => {
    let authorImg = <img className="h-full w-full rounded-full" src=author.imgUrl />

    <div className="flex items-center">
      <div className="w-10 h-10 bg-berry-40 block rounded-full mr-3"> authorImg </div>
      <div className="body-sm">
        <a
          href={switch author.social {
          | X(handle) => "https://x.com/" ++ handle
          | Bluesky(handle) => "https://bsky.app/profile/" ++ handle
          }}
          className="hover:text-gray-80"
          rel="noopener noreferrer"
        >
          {React.string(author.fullname)}
        </a>
        <div className="text-gray-60"> {React.string(author.role)} </div>
      </div>
    </div>
  }
}

module BlogHeader = {
  @react.component
  let make = (
    ~date: DateStr.t,
    ~author: BlogFrontmatter.author,
    ~co_authors: array<BlogFrontmatter.author>,
    ~title: string,
    ~category: option<string>=?,
    ~description: option<string>,
    ~articleImg: option<string>,
  ) => {
    let date = DateStr.toDate(date)

    let authors = Array.concat([author], co_authors)

    Console.log2("authors", authors)

    <div className="flex flex-col items-center">
      <div className="w-full max-w-740">
        <div className="text-gray-60 body-sm mb-5">
          {switch category {
          | Some(category) =>
            <>
              {React.string(category)}
              {React.string(middleDotSpacer)}
            </>
          | None => React.null
          }}
          {React.string(Util.Date.toDayMonthYear(date))}
        </div>
        <h1 className="hl-title"> {React.string(title)} </h1>
        {description->Option.mapOr(React.null, desc =>
          switch desc {
          | "" => <div className="mb-8" />
          | desc =>
            <div className="text-gray-80 mt-1 mb-8">
              <p className="body-lg"> {React.string(desc)} </p>
            </div>
          }
        )}
        <div className="flex flex-col md:flex-row mb-12">
          {Array.map(authors, author =>
            <div key=author.username className="mt-4 md:mt-0 md:ml-8 first:ml-0 min-w-32.75">
              <AuthorBox author />
            </div>
          )->React.array}
        </div>
      </div>
      {switch articleImg {
      | Some(articleImg) =>
        <div className="-mx-8 sm:mx-0 sm:w-full bg-gray-5-tr md:mt-24">
          <img className="h-full w-full object-cover max-h-134.5" src=articleImg />
        </div>
      | None =>
        <div className="max-w-740 w-full">
          <Line />
        </div>
      }}
    </div>
  }
}

let make = (props: props) => {
  let {children, isArchived, path, frontmatter} = props

  let archivedNote = isArchived
    ? {
        open Markdown
        <div className="mb-10">
          <Warn>
            <P>
              <span className="font-bold"> {React.string("Important: ")} </span>
              {React.string(
                "This is an archived blog post, kept for historical reasons. Please note that this information might be outdated.",
              )}
            </P>
          </Warn>
        </div>
      }
    : React.null

  let {date, author, co_authors, title, description, articleImg, previewImg} = frontmatter

  <MainLayout>
    <div className="w-full">
      <Meta
        siteName="ReScript Blog"
        title={title ++ " | ReScript Blog"}
        description=?{description->Nullable.toOption}
        ogImage={previewImg->Nullable.toOption->Option.getOr(Blog.defaultPreviewImg)}
      />
      <div className="mb-10 md:mb-20">
        <BlogHeader
          date
          author
          co_authors
          title
          description={description->Nullable.toOption}
          articleImg={articleImg->Nullable.toOption}
        />
      </div>
      <div className="flex justify-center">
        <div className="max-w-740 w-full">
          archivedNote
          children
          <div className="mt-12">
            <Line />
            <div className="pt-20 flex flex-col items-center">
              <div className="text-24 sm:text-32 text-center text-gray-80 font-medium">
                {React.string("Want to read more?")}
              </div>
              // <ReactRouter.Link
              //   to={("/blog" :> ReactRouter.Link.to)} className="text-fire hover:text-fire-70">
              //   {React.string("Back to Overview")}
              //   <Icon.ArrowRight className="ml-2 inline-block" />
              // </ReactRouter.Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  </MainLayout>
}
