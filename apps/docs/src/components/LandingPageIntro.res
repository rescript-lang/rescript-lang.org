@react.component
let make = () => {
  <section dataTestId="landing-intro" className="flex justify-center">
    <div className="max-w-1060 flex flex-col items-center px-5 sm:px-8 lg:box-content">
      <h1 className="hl-title text-center max-w-212">
        {React.string("JavaScript Made Simple for Humans and AI")}
      </h1>
      <h2 className="red-hat-mono-bold hl-1 text-center text-gray-60 my-4 max-w-md">
        {React.string(`Types > Vibes`)}
      </h2>
      <p className="body-lg text-center text-gray-60 mt-4 max-w-md">
        {React.string(`ReScript is a strongly typed language that compiles to clean,
            efficient JavaScript that humans and AI tools can read and understand.`)}
      </p>
      <p className="body-lg text-center text-gray-60 my-4 max-w-md">
        {React.string(`Its fast compiler and static type system keep feedback loops tight,
            so you can move quickly with AI assistance while maintaining
            confidence as your codebase grows.`)}
      </p>
      <ReactRouter.Link
        to=#"/docs/manual/installation" prefetch=#viewport className="mt-4 mb-2 block"
      >
        <Button> {React.string("Get started")} </Button>
      </ReactRouter.Link>
    </div>
  </section>
}
