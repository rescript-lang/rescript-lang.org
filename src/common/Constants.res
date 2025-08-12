type env = {
  @as("VITE_VERSION_LATEST")
  latestVersion: string,
  @as("VITE_VERSION_NEXT")
  nextVersion: string,
}

@scope("import.meta") external env: env = "env"

type versionMapping = {
  latest: string,
  next: string,
}

let versions = {
  latest: env.latestVersion,
  next: env.nextVersion,
}

Console.log(versions)

let latestVersion = (versions.latest, versions.latest->Semver.tryGetMajorString)

// This is used for the version dropdown in the manual layouts
let allManualVersions = [
  latestVersion,
  ("v10.0.0", "v9.1 - v10.1"),
  ("v9.0.0", "v8.2 - v9.0"),
  ("v8.0.0", "v6.0 - v8.2"),
]

let nextVersion =
  versions.latest === versions.next
    ? None
    : Some(versions.next, versions.next->Semver.tryGetMajorString)

let stdlibVersions =
  versions.latest === "v11.0.0" ? [latestVersion] : [("v11.0.0", "v11"), latestVersion]

let latestReactVersion = "latest"
let allReactVersions = [
  ("latest", latestReactVersion),
  ("v0.11.0", "v0.11.0"),
  ("v0.10.0", "v0.10.0"),
]

let dropdownLabelNext = "--- Next ---"
let dropdownLabelReleased = "--- Released ---"

// Used for the DocsOverview and collapsible navigation
let languageManual = version => {
  [
    ("Overview", `/docs/manual/${version}/introduction`),
    ("Language Features", `/docs/manual/${version}/overview`),
    ("JS Interop", `/docs/manual/${version}/embed-raw-javascript`),
    ("Build System", `/docs/manual/${version}/build-overview`),
  ]
}

let tools = [("Syntax Lookup", "/syntax-lookup")]

let githubHref = "https://github.com/rescript-lang/rescript"
let xHref = "https://x.com/rescriptlang"
let blueSkyHref = "https://bsky.app/profile/rescript-lang.org"
let discourseHref = "https://forum.rescript-lang.org"
