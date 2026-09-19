@react.component
let make = () => {
  <section
    dataTestId="landing-other-selling-points"
    className="flex justify-center w-full bg-gray-90 border-t border-gray-80
          px-4 sm:px-8 lg:px-16 pt-24 pb-20 "
  >
    <div className="max-w-1060 grid grid-cols-4 md:grid-cols-10 grid-rows-2 gap-8">
      <div className="pb-24 md:pb-32 row-span-2 row-start-1 col-start-1 col-span-4 md:col-span-6">
        <ImageGallery
          className="w-full "
          imgClassName="w-full h-[25.9rem] object-cover rounded-lg"
          imgSrcs={["/lp/community-3.avif", "/lp/community-2.avif", "/lp/community-1.avif"]}
          imgLoading=#lazy
        />
        <h3 className="hl-3 text-gray-20 mt-4 mb-2">
          {React.string(`A community of programmers who value getting things done`)}
        </h3>
        <p className="body-md text-gray-40">
          {React.string(`No language can be popular without a solid
          community. A great type system isn't useful if library authors
          abuse it. Performance doesn't show if all the libraries are slow.
          Join the ReScript community — A group of companies and individuals
          who deeply care about simplicity, speed and practicality.`)}
        </p>
        <a href="https://forum.rescript-lang.org" className="mt-6 inline-block">
          <Button size={Button.Small} kind={Button.PrimaryBlue}>
            {React.string("Join our Forum")}
          </Button>
        </a>
      </div>
      <div className="col-span-4 lg:row-start-1">
        <img
          className="w-full rounded-lg border-2 border-turtle-dark" src="/lp/editor-tooling-1.avif"
        />
        <h3 className="hl-3 text-gray-20 mt-6 mb-2">
          {React.string(`Tooling that just works out of the box`)}
        </h3>
        <p className="body-md text-gray-40">
          {React.string(`A builtin pretty printer, memory friendly
          VSCode & Vim plugins, a stable type system and compiler that doesn't require lots
          of extra configuration. ReScript brings all the tools you need to
          build reliable JavaScript, Node and ReactJS applications.`)}
        </p>
      </div>
      <div className="col-span-4 lg:row-start-2">
        <img className="w-full rounded-lg border-2 border-fire-30" src="/lp/easy-to-unadopt.avif" />
        <h3 className="hl-3 text-gray-20 mt-6 mb-2">
          {React.string(`Easy to adopt — without any lock-in`)}
        </h3>
        <p className="body-md text-gray-40">
          {React.string(`ReScript was made with gradual adoption in mind.  If
          you ever want to go back to plain JavaScript, just remove all
          source files and keep its clean JavaScript output. Tell
          your coworkers that your project will keep functioning with or
          without ReScript!`)}
        </p>
      </div>
    </div>
  </section>
}
