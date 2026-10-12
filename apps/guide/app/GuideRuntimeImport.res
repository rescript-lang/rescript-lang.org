let capitalizeFirstLetter = string => {
  let firstLetter = string->String.charAt(0)->String.toUpperCase
  `${firstLetter}${string->String.slice(~start=1)}`
}

let filenameForCompiler = (~compilerVersion: Semver.t, path) => {
  let filename = path->String.slice(~start=9)
  switch compilerVersion {
  | {major: 12, minor: 0, patch: 0, preRelease: Some(Alpha(alpha))} if alpha < 8 =>
    let filename = if filename->String.startsWith("core__") {
      filename->String.slice(~start=6)
    } else {
      filename
    }
    filename->capitalizeFirstLetter
  | {major} if major < 12 && filename->String.startsWith("core__") =>
    filename->capitalizeFirstLetter
  | _ => filename
  }
}

let compilerVersionForRuntimeImport = (compilerVersion: Semver.t) =>
  // Older compiler builds emitted stdlib import paths that no longer match the CDN layout.
  switch compilerVersion {
  | {major: 12, minor: 0, patch: 0, preRelease: Some(Alpha(alpha))} if alpha < 9 => {
      Semver.major: 12,
      minor: 0,
      patch: 0,
      preRelease: Some(Alpha(9)),
    }
  | {major, minor} if (major === 11 && minor < 2) || major < 11 => {
      major: 11,
      minor: 2,
      patch: 0,
      preRelease: Some(Beta(2)),
    }
  | version => version
  }

let url = (~bundleBaseUrl, ~compilerVersion: Semver.t, path) => {
  let filename = path->filenameForCompiler(~compilerVersion)
  let compilerVersion = compilerVersion->compilerVersionForRuntimeImport

  CompilerManagerHook.CdnMeta.getStdlibRuntimeUrl(bundleBaseUrl, compilerVersion, filename)
}
