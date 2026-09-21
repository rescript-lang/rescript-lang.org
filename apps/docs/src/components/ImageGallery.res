@react.component
let make = (
  ~className="",
  ~imgClassName="",
  ~images: array<ImageAsset.t>,
  ~imgSizes="100vw",
  ~imgLoading=?,
) => {
  let (selected, setSelected) = React.useState(_ => 0)
  let count = Array.length(images)
  let index = selected < count ? selected : 0

  if selected !== index {
    setSelected(_ => index)
  }

  switch images->Array.get(index) {
  | None => React.null
  | Some(image) =>
    <div className>
      <button
        type_="button"
        className="block w-full"
        ariaLabel="Next community photo"
        onClick={_ => setSelected(_ => index + 1 < count ? index + 1 : 0)}
      >
        <ResponsiveImage
          key=image.src
          className={`gallery-photo ${imgClassName}`}
          image
          sizes=imgSizes
          alt={`ReScript community photo ${(index + 1)->Int.toString}`}
          loading=?imgLoading
        />
      </button>
      <div className="flex space-x-2 mt-4">
        {images
        ->Array.mapWithIndex((image, i) => {
          let color = i === index ? "text-gray-40" : "text-gray-70"
          <button
            key=image.src
            type_="button"
            ariaLabel={`Show community photo ${(i + 1)->Int.toString}`}
            ariaPressed={i === index ? #"true" : #"false"}
            className={`gallery-selector flex items-center hover:cursor-pointer hover:text-gray-40 h-8 w-8 ${color}`}
            onClick={_ => setSelected(_ => i)}
          />
        })
        ->React.array}
      </div>
    </div>
  }
}
