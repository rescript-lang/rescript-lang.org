@react.component
let make = () => {
  let {pathname} = ReactRouter.useLocation()

  let paths = (pathname :> string)->String.split("/")->Array.filter(path => path != "")

  let lastIndex = paths->Array.length - 1

  <div className="w-full captions overflow-x-auto text-gray-60 mb-8">
    {paths
    ->Array.mapWithIndex((path, i) =>
      <>
        <ReactRouter.Link.String key={path} to=path prefetch={#intent}>
          {React.string(path->String.capitalize)}
        </ReactRouter.Link.String>
        {i == lastIndex ? React.null : React.string(" / ")}
      </>
    )
    ->React.array}
  </div>
}
