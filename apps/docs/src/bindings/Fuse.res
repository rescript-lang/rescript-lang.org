module Options = {
  type t = {
    shouldSort?: bool,
    includeScore?: bool,
    threshold?: float,
    location?: int,
    distance?: int,
    ignoreLocation?: bool,
    minMatchCharLength?: int,
    keys?: array<string>,
  }
}

type t<'data>

type match<'data> = {"item": 'data, "score": float}

@new @module("fuse.js")
external make: (array<'data>, Options.t) => t<'a> = "default"

@send external search: (t<'data>, string) => array<match<'data>> = "search"
