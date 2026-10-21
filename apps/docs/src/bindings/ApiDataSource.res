@module("../../scripts/api-data.mjs")
external latestVersion: (~major: string, array<string>) => string = "latestApiVersion"

type options = {directory: string, major?: string}
@module("../../scripts/api-data.mjs")
external directory: (~options: options) => string = "apiDataDirectory"
