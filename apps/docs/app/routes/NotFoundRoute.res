let loader = async _ => ReactRouter.data(JSON.Null, {status: 404})

// Pages serves unknown paths from static 404.html. Client navigation does not
// need a server data request to render this page.
let clientLoader = async _ => JSON.Null

@react.component
let default = () => {
  <>
    <title> {React.string("Page Not Found | ReScript")} </title>
    <meta name="robots" content="noindex" />
    <div className="pt-36 text-center flex flex-col gap-6 text-gray-80 w-fit mx-auto">
      <h1 className="hl-title"> {React.string("404")} </h1>
      <h2 className="text-32"> {React.string("Page Not Found")} </h2>
      <p> {React.string("Oops! The page you're looking for doesn't exist.")} </p>
      <a href="/" className=" text-fire no-underline hover:underline">
        {React.string("Return home")}
      </a>
    </div>
  </>
}
