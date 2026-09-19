@react.component
let make = (~poster, ~src) =>
  NativeMedia.createVideo(
    {className: "rounded-lg", controls: true, poster, width: 1750, height: 1116, preload: #none},
    <source src type_="video/mp4" />,
  )
