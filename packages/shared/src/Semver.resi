@unboxed
type prerelease = String(string) | Number(int)

type t = {
  raw: string,
  major: int,
  minor: int,
  patch: int,
  prerelease: array<prerelease>,
  build: array<string>,
  version: string,
}

let make: (
  ~major: int,
  ~minor: int,
  ~patch: int,
  ~prerelease: [#alpha(int) | #beta(int) | #rc(int) | #dev(int)],
) => t

let parse: string => option<t>

let toString: t => string

let tryGetMajorString: string => string

@module("semver")
external rcompare: (string, string) => int = "rcompare"
