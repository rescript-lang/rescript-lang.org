@react.component
let make = () => {
  <section dataTestId="landing-quick-install" className="my-32 sm:px-4 sm:flex sm:justify-center">
    <div className="max-w-1060 flex flex-col w-full px-5 md:px-8 lg:px-8 lg:box-content ">
      <p
        className="relative z-1 max-w-112 space-y-12 text-gray-80 font-semibold text-24 md:text-32 leading-2"
      >
        <span className="bg-fire-5 rounded-lg border border-fire-10 p-1 ">
          {React.string(`Leverage the full power`)}
        </span>
        {React.string(` of JavaScript in a robustly typed language without the fear of \`any\` types.`)}
      </p>
      <div className="w-full mt-12 md:flex flex-col lg:flex-row md:justify-between ">
        <p
          className="relative z-1 text-gray-80 font-semibold text-24 md:text-32 leading-2 max-w-lg"
        >
          {React.string(`ReScript is used to ship and maintain mission-critical products with good UI and UX.`)}
        </p>
        <LandingPageInstallInstructions className="mt-16 lg:mt-0 self-end" />
      </div>
    </div>
  </section>
}
