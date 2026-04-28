module Link = ReactRouter.Link

@react.component
let make = (~crumbs: list<Url.breadcrumb>) => {
  let {pathname} = ReactRouter.useLocation()

  let lastSegment =
    (pathname :> string)
    ->String.split("/")
    ->Array.filter(segment =>
      segment !== "docs" &&
      segment !== "manual" &&
      segment !== "react" &&
      segment !== "api" &&
      segment !== ""
    )
    ->Array.last

  let crumbs = switch lastSegment {
  | Some(lastSegment) =>
    crumbs->List.concat(list{
      {Url.name: lastSegment->String.capitalize, href: (pathname :> string)},
    })
  | None => crumbs
  }

  <div className="w-full captions overflow-x-auto text-gray-60">
    {List.mapWithIndex(crumbs, (crumb, i) => {
      let item = if i === List.length(crumbs) - 1 {
        <span key={Int.toString(i)}> {React.string(crumb.name)} </span>
      } else {
        <Link.String key={Int.toString(i)} to=crumb.href prefetch={#intent}>
          {React.string(crumb.name)}
        </Link.String>
      }
      if i > 0 {
        <span key={Int.toString(i)}>
          {React.string(" / ")}
          item
        </span>
      } else {
        item
      }
    })
    ->List.toArray
    ->React.array}
  </div>
}
