type preRelease =
  | Alpha(int)
  | Beta(int)
  | Dev(int)
  | Rc(int)

type t = {
  major: int,
  minor: int,
  patch: int,
  preRelease: option<preRelease>,
}

let parse: string => option<t>

let toString: t => string

let tryGetMajorString: string => string
