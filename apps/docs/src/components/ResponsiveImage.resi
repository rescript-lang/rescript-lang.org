@react.component
let make: (
  ~image: ImageAsset.t,
  ~sizes: string,
  ~alt: string,
  ~className: string=?,
  ~loading: [#eager | #lazy]=?,
) => React.element
