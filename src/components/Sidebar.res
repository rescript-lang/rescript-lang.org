type item = {
  slug: string,
  title: string,
}

@react.component
let make = (~items) => {
  <ul
    id="sidebar"
    popover=Auto
    className="overflow-y-scroll pl-10 w-80 pt-8 border-gray-20 border-r-2 backdrop:bg-black/40 backdrop:backdrop-blur-xs md:basis-45 open:w-16 backdrop:overflow-hidden"
  >
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
