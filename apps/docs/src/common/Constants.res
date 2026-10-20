external latestVersion: string = "import.meta.env.VITE_VERSION_LATEST"

let docSearchVersionTokens = [latestVersion->Semver.tryGetMajorString, "latest"]

// Used for the DocsOverview
let languageManual = [
  ("Overview", "/docs/manual/introduction"),
  ("Language Features", "/docs/manual/overview"),
  ("JS Interop", "/docs/manual/embed-raw-javascript"),
  ("Build System", "/docs/manual/build-overview"),
]

let tools = [("Syntax Lookup", "/syntax-lookup")]

let githubHref = "https://github.com/rescript-lang/rescript"
let xHref = "https://x.com/rescriptlang"
let blueSkyHref = "https://bsky.app/profile/rescript-lang.org"
let discourseHref = "https://forum.rescript-lang.org"
