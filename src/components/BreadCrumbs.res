@react.component
let make = () => {
  let {pathname} = ReactRouter.useLocation()

  let paths = (pathname :> string)->String.split("/")->Array.filter(path => path != "")

  let lastIndex = paths->Array.length - 1

  <div className="w-full captions overflow-x-auto text-gray-60 mb-8">
    {paths
    ->Array.mapWithIndex((path, i) => {
      let cumulativePath =
        "/" ++ (paths->Array.slice(0, i + 1)->Array.joinWith("/"))

      <React.Fragment key={cumulativePath}>
        <ReactRouter.Link.String to=cumulativePath prefetch={#intent}>
          {React.string(path->String.capitalize)}
        </ReactRouter.Link.String>
        {i == lastIndex ? React.null : React.string(" / ")}
      </React.Fragment>
    })
    ->React.array}
  </div>
}
