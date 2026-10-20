@react.component
let make =
  @directive("'use memo'")
  (~playgroundData) => {
    <>
      <Meta
        title="The ReScript Programming Language"
        description={`JavaScript Made Simple for Humans and AI. ReScript is a strongly typed language that compiles to clean,
        efficient JavaScript that humans and AI tools can read and understand.
        Its fast compiler and static type system keep feedback loops tight,
        so you can move quickly with AI assistance while maintaining
        confidence as your codebase grows.`}
        keywords=["ReScript", "rescriptlang", "JavaScript", "JS", "TypeScript"]
      />
      <div className="homepage-fonts absolute top-16 z w-full text-18 text-gray-80">
        <div className="relative overflow-hidden pb-32">
          <main className="mt-10 min-w-320 w-full lg:align-center">
            <div className="mt-16 md:mt-32 lg:mt-40 mb-12">
              <LandingPageIntro />
            </div>
            <LandingPagePlayground playgroundData />
            <LandingPageQuickInstall />
            <LandingPageMainSellingPoints />
            <LandingPageOtherSellingPoints />
            <LandingPageTrustedBy />
            <LandingPageCuratedResources />
          </main>
        </div>
        <Footer />
      </div>
    </>
  }
