type route
type config = {routes: array<route>}
type options = {contentDirectory?: string}

@module("../../route-config.mjs")
external loadRoutes: (~options: options=?) => config = "loadRoutes"

@module("../../generate-route-types.mjs")
external concretePaths: array<route> => array<string> = "concretePaths"
