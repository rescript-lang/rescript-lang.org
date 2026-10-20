type imageProps = {
  className: string,
  alt: string,
  src: string,
  srcSet: option<string>,
  sizes: string,
  width: int,
  height: int,
  loading: option<[#eager | #lazy]>,
  decoding: [#async],
}

type videoProps = {
  className: string,
  controls: bool,
  poster: string,
  width: int,
  height: int,
  preload: [#none],
}

// The installed JSX DOM bindings omit the native decoding and preload attributes.
@module("react")
external createImage: (@as("img") _, imageProps) => React.element = "createElement"

@module("react")
external createVideo: (@as("video") _, videoProps, React.element) => React.element = "createElement"
