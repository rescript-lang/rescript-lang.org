// This module establishes the communication to the
// loaded bucklescript API exposed by the bs-platform-js
// bundle

// It is only safe to call these functions when a bundle
// has been loaded, so we'd prefer to protect this
// API with the playground compiler manager state

module Lang: {
  type t =
    | Reason
    | Res

  let toString: t => string

  let toExt: t => string

  let decode: JSON.t => t
}

module Version: {
  type t =
    | V1
    | V2
    | V3
    | V4
    | V5
    | UnknownVersion(string)

  // Helps finding the right API version
  let fromString: string => t

  let toString: t => string

  let defaultTargetLang: Lang.t

  let availableLanguages: t => array<Lang.t>
}

module LocMsg: {
  type t = {
    fullMsg: string,
    shortMsg: string,
    row: int,
    column: int,
    endRow: int,
    endColumn: int,
  }

  let decode: JSON.t => t

  type prefix = [#W | #E]

  // Useful for showing errors in a more compact format
  let toCompactErrorLine: (~prefix: prefix, t) => string

  // Creates a somewhat unique id based on the rows / cols of the locMsg
  let makeId: t => string

  /* let dedupe: (array<t>) => array<t> */
}

module Warning: {
  type t =
    | Warn({warnNumber: int, details: LocMsg.t})
    | WarnErr({warnNumber: int, details: LocMsg.t}) // Describes an erronous warning

  let decode: JSON.t => t

  // Useful for showing errors in a more compact format
  let toCompactErrorLine: t => string
}

module WarningFlag: {
  type t = {
    msg: string,
    warn_flags: string,
    warn_error_flags: string,
  }

  let decode: JSON.t => t
}

module TypeHint: {
  type position = {
    line: int,
    col: int,
  }
  type data = {
    start: position,
    end: position,
    hint: string,
  }

  type t =
    | TypeDeclaration(data)
    | Expression(data)
    | Binding(data)
    | CoreType(data)

  let decode: JSON.t => t
}

module CompileSuccess: {
  type t = {
    @as("js_code")
    jsCode: string,
    warnings: array<Warning.t>,
    @as("type_hints")
    typeHints: array<TypeHint.t>, // Not supported in older versions <= 9.0.1 (will always be [])
    time: float, // total compilation time
  }

  let decode: (~time: float, JSON.t) => t
}

module ConvertSuccess: {
  type t = {
    code: string,
    fromLang: Lang.t,
    toLang: Lang.t,
  }

  let decode: JSON.t => t
}

module CompileFail: {
  type t =
    | SyntaxErr(array<LocMsg.t>)
    | TypecheckErr(array<LocMsg.t>)
    | WarningErr(array<Warning.t>)
    | WarningFlagErr(WarningFlag.t)
    | OtherErr(array<LocMsg.t>)

  let decode: JSON.t => t
}

module CompilationResult: {
  type t =
    | Fail(CompileFail.t) // When a compilation failed with some error result
    | Success(CompileSuccess.t)
    | UnexpectedError(string) // Errors that slip through as uncaught exceptions of the compiler bundle
    | Unknown(string, JSON.t)

  // TODO: We might change this specific api completely before launching
  let decode: (~time: float, JSON.t) => t
}

module ConversionResult: {
  type t =
    | Success(ConvertSuccess.t)
    | Fail({fromLang: Lang.t, toLang: Lang.t, details: array<LocMsg.t>}) // When a compilation failed with some error result
    | UnexpectedError(string) // Errors that slip through as uncaught exceptions within the playground
    | Unknown(string, JSON.t)

  let decode: (~fromLang: Lang.t, ~toLang: Lang.t, JSON.t) => t
}

module Config: {
  type t = {
    module_system: string,
    warn_flags: string,
    /** Only available in apiVersion > 3 (= ReScript 11+) */
    uncurried?: bool,
    open_modules?: array<string>,
  }
}

module Compiler: {
  type t

  // Factory
  @val @scope("rescript_compiler") external make: unit => t = "make"

  let version: t => string

  /*
   * Res compiler actions
   */
  let resVersion: t => string
  let resCompile: (t, string) => CompilationResult.t
  let resFormat: (t, string) => ConversionResult.t

  /*
   * Reason compiler actions
   */
  let reasonCompile: (t, string) => CompilationResult.t
  let reasonFormat: (t, string) => ConversionResult.t

  /*
   * OCaml compiler actions (Note: no pretty print available for OCaml)
   */
  let ocamlVersion: t => option<string>

  /*
   * Config setter / getters
   */
  let getConfig: t => Config.t
  let setFilename: (t, string) => bool
  let setModuleSystem: (t, [#es6 | #nodejs]) => bool

  let setWarnFlags: (t, string) => bool
  let setOpenModules: (t, array<string>) => bool
  let setConfig: (t, Config.t) => unit

  // General format function
  let convertSyntax: (~fromLang: Lang.t, ~toLang: Lang.t, ~code: string, t) => ConversionResult.t
}

// This needs to be an external, otherwise the JS tries to access the value
// on load
@val @scope("rescript_compiler")
external apiVersion: string = "api_version"
