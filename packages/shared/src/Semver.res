// https://github.com/DefinitelyTyped/DefinitelyTyped/blob/e9bf31782c3f5b69a778ab4077c3e48a781e33cb/types/semver/classes/semver.d.ts#L4

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

module NpmSemver = {
  @module("semver") external parse: string => Null.t<t> = "parse"
  @new @module("semver") external make: string => Null.t<t> = "SemVer"
}

let make = (
  ~major,
  ~minor,
  ~patch,
  ~prerelease: [#alpha(int) | #beta(int) | #rc(int) | #dev(int)],
) => {
  let pre = switch prerelease {
  | #alpha(v) => `alpha.${v->Int.toString}`
  | #beta(v) => `beta.${v->Int.toString}`
  | #rc(v) => `rc.${v->Int.toString}`
  | #dev(v) => `dev.${v->Int.toString}`
  }
  NpmSemver.make(
    `${major->Int.toString}.${minor->Int.toString}.${patch->Int.toString}-${pre}`,
  )->Null.getOrThrow
}

/**
  Takes a semver string accepted by the npm `semver` package, including strings
  prefixed with "v", and adapts it to the local version record.
  */
let parse = (versionStr: string) => versionStr->NpmSemver.parse->Null.toOption

let toString = t => t.raw

let tryGetMajorString = (versionStr: string) =>
  switch versionStr->parse {
  | None => versionStr
  | Some({major}) => "v" ++ major->Int.toString
  }

@module("semver")
external rcompare: (string, string) => int = "rcompare"
