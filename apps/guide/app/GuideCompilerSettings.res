// Upgrade deliberately, together with the lesson validation run.
let version = "v12.3.1"
let parsedVersion = version->Semver.parse->Option.getOrThrow
let moduleSystem = "esmodule"
let warnFlags = "+a-4-9-20-40-41-42-50-61-102-109"
let loadingTimeoutMs = 15000
