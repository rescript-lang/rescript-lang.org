let moduleSystem = "esmodule"
let warnFlags = "+a-4-9-20-40-41-42-50-61-102-109"

let isSupportedVersion = (version: Semver.t) =>
  switch version.major {
  | 8 | 9 => false
  | 10 => version.minor >= 1
  | 11 => version.minor >= 1 && version.preRelease->Option.isNone
  | 12 =>
    switch version.preRelease {
    | None => true
    | Some(_) => version.minor > 1
    }
  | _ => true
  }

let compareIntDescending = (a, b) => {
  if a > b {
    -1.0
  } else if a < b {
    1.0
  } else {
    0.0
  }
}

let compareVersionDescending = (a: Semver.t, b: Semver.t) => {
  switch compareIntDescending(a.major, b.major) {
  | 0.0 =>
    switch compareIntDescending(a.minor, b.minor) {
    | 0.0 => compareIntDescending(a.patch, b.patch)
    | result => result
    }
  | result => result
  }
}

let supportedVersions = versions =>
  versions
  ->Array.filterMap(Semver.parse)
  ->Array.filter(isSupportedVersion)
  ->Array.toSorted(compareVersionDescending)

let latestStableParsedVersion = (versions: array<Semver.t>) =>
  versions->Array.find(version => version.preRelease->Option.isNone)

let latestStableVersion = versions => versions->supportedVersions->latestStableParsedVersion
