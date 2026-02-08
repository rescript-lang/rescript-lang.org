type item = {
  slug: string,
  title: string,
}

@react.component
let make = (~items) => {
  <ul className="md:basis-45 md:grow hidden md:block ml-10 pt-8 border-gray-20 border-r-2 h-auto">
    {items
    ->Array.map(item =>
      <li
        className="block py-1 md:h-auto tracking-tight text-gray-60 rounded-sm hover:bg-gray-20 hover:-ml-2 hover:py-1 hover:pl-2"
      >
        <ReactRouter.Link.String to={"/guide/" ++ item.slug}>
          {React.string(item.title)}
        </ReactRouter.Link.String>
      </li>
    )
    ->React.array}
  </ul>
}
