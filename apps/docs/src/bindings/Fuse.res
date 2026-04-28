module Options = {
  @deriving(abstract)
  type t = {
    @optional
    shouldSort: bool,
    @optional
    includeScore: bool,
    @optional
    threshold: float,
    @optional
    location: int,
    @optional
    distance: int,
    @optional
    ignoreLocation: bool,
    @optional
    minMatchCharLength: int,
    @optional
    keys: array<string>,
  }
}

type t<'data>

type match<'data> = {"item": 'data, "score": float}

@new @module("fuse.js")
external make: (array<'data>, Options.t) => t<'a> = "default"

@send external search: (t<'data>, string) => array<match<'data>> = "search"
