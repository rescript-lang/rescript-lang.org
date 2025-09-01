// This is the implementation of the _app.js file

// Resources:
// --------------
// Really good article on state persistence within layouts:
// https://adamwathan.me/2019/10/17/persistent-layout-patterns-in-nextjs/

// Register all the highlightjs stuff for the whole application

type pageComponent = React.component<{.}>
type pageProps = {.}

type props = {"Component": pageComponent, "pageProps": pageProps}

@get
external frontmatter: React.component<{.}> => JSON.t = "frontmatter"

let make = (props: props): React.element => {
  let component = props["Component"]
  let pageProps = props["pageProps"]

  let router = Next.Router.useRouter()

  let content = React.createElement(component, pageProps)

  let url = router.route->Url.parse

  switch url {
  // landing page
  | {base: [], pagepath: []} => <LandingPageLayout> content </LandingPageLayout>
  // docs routes
  | {base: ["docs", "manual"], pagepath} =>
    // check if it's an api route
    switch pagepath[0] {
    | Some("api") =>
      switch url->Url.getVersionString {
      | ("v11.0.0" | "v12.0.0") as version =>
        switch (Array.length(pagepath), pagepath[1]) {
        | (1, _) => <ApiOverviewLayout.Docs version> content </ApiOverviewLayout.Docs>
        | _ => content
        }
      | _ => content
      }
    | _ =>
      switch url->Url.getVersionString {
      | "v8.0.0" =>
        <ManualDocsLayout.V800 frontmatter={component->frontmatter}>
          content
        </ManualDocsLayout.V800>
      | "v9.0.0" =>
        <ManualDocsLayout.V900 frontmatter={component->frontmatter}>
          content
        </ManualDocsLayout.V900>
      | "v10.0.0" =>
        <ManualDocsLayout.V1000 frontmatter={component->frontmatter}>
          content
        </ManualDocsLayout.V1000>
      | "v11.0.0" =>
        <ManualDocsLayout.V1100 frontmatter={component->frontmatter}>
          content
        </ManualDocsLayout.V1100>
      | "v12.0.0" =>
        <ManualDocsLayout.V1200 frontmatter={component->frontmatter}>
          content
        </ManualDocsLayout.V1200>
      | _ => React.null
      }
    }

  | {base: ["docs", "react"], version} =>
    switch version {
    | Latest =>
      <ReactDocsLayout.Latest frontmatter={component->frontmatter}>
        content
      </ReactDocsLayout.Latest>
    | Version("v0.10.0") =>
      <ReactDocsLayout.V0100 frontmatter={component->frontmatter}> content </ReactDocsLayout.V0100>
    | Version("v0.11.0") =>
      <ReactDocsLayout.V0110 frontmatter={component->frontmatter}> content </ReactDocsLayout.V0110>
    | _ => React.null
    }

  // common routes
  | {base} =>
    switch List.fromArray(base) {
    | list{"community", ..._rest} =>
      <CommunityLayout frontmatter={component->frontmatter}> content </CommunityLayout>

    | list{"try"} => content
    | list{"blog"} => content // Blog implements its own layout as well
    | list{"syntax-lookup"} => content
    | list{"packages"} => content
    | list{"blog", ..._rest} => // Here, the layout will be handled by the Blog_Article component
      // to keep the frontmatter parsing etc in one place
      content
    | _ =>
      let fm = component->frontmatter->DocFrontmatter.decode
      let title = switch url {
      | {base: ["docs"]} => Some("Overview | ReScript Documentation")
      | _ => Option.map(fm, fm => fm.title)
      }
      let description = Option.flatMap(fm, fm => Null.toOption(fm.description))
      <MainLayout>
        <Meta ?title ?description version=url.version />
        <div className="flex justify-center">
          <div className="max-w-740 w-full"> content </div>
        </div>
      </MainLayout>
    }
  }
}
