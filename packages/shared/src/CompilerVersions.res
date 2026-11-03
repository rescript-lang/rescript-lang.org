let isSupported = (version: Semver.t) =>
  switch version.major {
  | major if major < 10 => false
  | 10 => version.minor >= 1
  | 11 =>
    // Preserve the playground's minimum stable v11 version.
    version.preRelease->Option.isNone &&
      (version.minor > 1 || (version.minor === 1 && version.patch >= 4))
  | 12 => version.preRelease->Option.isNone || version.minor > 1
  | _ => true
  }

let supported = versions =>
  versions
  ->Array.filterMap(Semver.parse)
  ->Array.filter(isSupported)
  ->Array.toSorted((a, b) => Semver.compare(b, a))

let latestStable = versions =>
  versions->Array.find(version => version.Semver.preRelease->Option.isNone)
