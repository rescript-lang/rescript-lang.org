type rec route = {path?: string, index?: bool, children?: array<route>}
type config = {routes: array<route>}
type options = {contentDirectory?: string, apiDirectory?: string}

@module("../../route-config.mjs")
external loadRoutes: (~options: options=?) => config = "loadRoutes"

@module("../../generate-route-types.mjs")
external concretePaths: array<route> => array<string> = "concretePaths"

@module("../../generate-route-types.mjs")
external renderPathType: array<route> => string = "renderPathType"

type generationOptions = {routes: array<route>, destination: string, check?: bool}
@module("../../generate-route-types.mjs")
external generate: (~options: generationOptions) => bool = "generateRouteTypes"
