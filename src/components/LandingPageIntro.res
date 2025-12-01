@react.component
let make = () => {
  <section className="flex justify-center">
    <div className="max-w-1060 flex flex-col items-center px-5 sm:px-8 lg:box-content">
      <h1 className="hl-title text-center max-w-212">
        {React.string("Fast, Simple, Fully Typed JavaScript from the Future")}
      </h1>
      <h2 className="body-lg text-center text-gray-60 my-4 max-w-md">
        {React.string(`ReScript is a robustly typed language that compiles to efficient
            and human-readable JavaScript. It comes with a lightning fast
            compiler toolchain that scales to any codebase size.`)}
      </h2>
      <div className="mt-4 mb-2">
        <ReactRouter.Link to=#"/docs/manual/installation" prefetch=#viewport>
          <Button> {React.string("Get started")} </Button>
        </ReactRouter.Link>
      </div>
    </div>
  </section>
}
