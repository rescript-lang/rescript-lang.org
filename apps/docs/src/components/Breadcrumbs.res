module Link = ReactRouter.Link

let normalizeName = name => name->String.trim->String.toLowerCase

let endsWithCrumb = (~crumbs: list<Url.breadcrumb>, ~name) => {
  switch crumbs->List.toArray->Array.last {
  | Some(crumb) => crumb.name->normalizeName === name->normalizeName
  | None => false
  }
}

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

  let currentCrumb = switch lastSegment {
  | Some(lastSegment) =>
    Some({
      Url.name: lastSegment->String.capitalize,
      href: (pathname :> string),
    })
  | None => None
  }

  let crumbs = switch currentCrumb {
  | Some(currentCrumb) if !endsWithCrumb(~crumbs, ~name=currentCrumb.name) =>
    crumbs->List.concat(list{currentCrumb})
  | Some(_) | None => crumbs
  }

  <div dataTestId="breadcrumbs" className="w-full captions overflow-x-auto text-gray-60">
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
