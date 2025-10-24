@react.component
let default = () => {
  <div className="pt-36 text-center flex flex-col gap-6 text-gray-80 w-fit mx-auto">
    <h1 className="hl-title"> {React.string("404")} </h1>
    <h2 className="text-32"> {React.string("Page Not Found")} </h2>
    <p> {React.string("Oops! The page you're looking for doesn't exist.")} </p>
    <a href="/" className=" text-fire no-underline hover:underline">
      {React.string("Return home")}
    </a>
  </div>
}
