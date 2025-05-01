@val @scope("performance") external now: unit => float = "now"

module Lang = {
  type t =
    | Reason
    | Res

  let toString = t =>
    switch t {
    | Res => "ReScript"
    | Reason => "Reason"
    }

  let toExt = t =>
    switch t {
    | Res => "res"
    | Reason => "re"
    }

  let decode = (json): t => {
    open! Json.Decode
    switch string(json) {
    | "re" => Reason
    | "res" => Res
    | other => raise(DecodeError(`Unknown language "${other}"`))
    }
  }
}

module Version = {
  type t =
    | V1
    | V2
    | V3
    | V4
    | V5
    | UnknownVersion(string)

  // Helps finding the right API version
  let fromString = (apiVersion: string): t =>
    switch String.split(apiVersion, ".")->List.fromArray {
    | list{maj, min, ..._} =>
      let maj = Int.fromString(maj)
      let min = Int.fromString(min)

      switch (maj, min) {
      | (Some(maj), Some(_))
      | (Some(maj), None) =>
        if maj >= 1 {
          V1
        } else {
          UnknownVersion(apiVersion)
        }
      | _ => UnknownVersion(apiVersion)
      }
    | list{"2"} => V2
    | list{"3"} => V3
    | list{"4"} => V4
    | list{"5"} => V5
    | _ => UnknownVersion(apiVersion)
    }

  let toString = t =>
    switch t {
    | V1 => "1.0"
    | V2 => "2.0"
    | V3 => "3.0"
    | V4 => "4.0"
    | V5 => "5.0"
    | UnknownVersion(version) => version
    }

  let defaultTargetLang = Lang.Res

  let availableLanguages = t =>
    switch t {
    | V1 => [Lang.Reason, Res]
    | V2 | V3 | V4 | V5 => [Lang.Res]
    | UnknownVersion(_) => [Res]
    }
}

module LocMsg = {
  type t = {
    fullMsg: string,
    shortMsg: string,
    row: int,
    column: int,
    endRow: int,
    endColumn: int,
  }

  let decode = (json): t => {
    open Json.Decode
    {
      fullMsg: json->field("fullMsg", string, _),
      shortMsg: json->field("shortMsg", string, _),
      row: json->field("row", int, _),
      column: json->field("column", int, _),
      endRow: json->field("endRow", int, _),
      endColumn: json->field("endColumn", int, _),
    }
  }

  type prefix = [#W | #E]

  // Useful for showing errors in a more compact format
  let toCompactErrorLine = (~prefix: prefix, locMsg: t) => {
    let {row, column, shortMsg} = locMsg
    let prefix = switch prefix {
    | #W => "W"
    | #E => "E"
    }

    `[1;31m[${prefix}] Line ${row->Int.toString}, ${column->Int.toString}:[0m ${shortMsg}`
  }

  // Creates a somewhat unique id based on the rows / cols of the locMsg
  let makeId = t => {
    open Int
    toString(t.row) ++
    ("-" ++
    (toString(t.endRow) ++ ("-" ++ (toString(t.column) ++ ("-" ++ toString(t.endColumn))))))
  }

  let dedupe = (arr: array<t>) => {
    let result = Dict.make()

    for i in 0 to Array.length(arr) - 1 {
      let locMsg = Array.getUnsafe(arr, i)
      let id = makeId(locMsg)

      // The last element with the same id wins
      result->Dict.set(id, locMsg)
    }
    Dict.valuesToArray(result)
  }
}

module Warning = {
  type t =
    | Warn({warnNumber: int, details: LocMsg.t})
    | WarnErr({warnNumber: int, details: LocMsg.t}) // Describes an erronous warning

  let decode = (json): t => {
    open! Json.Decode

    let warnNumber = field("warnNumber", int, json)
    let details = LocMsg.decode(json)

    field("isError", bool, json) ? WarnErr({warnNumber, details}) : Warn({warnNumber, details})
  }

  // Useful for showing errors in a more compact format
  let toCompactErrorLine = (t: t) => {
    let prefix = switch t {
    | Warn(_) => "W"
    | WarnErr(_) => "E"
    }

    let (row, column, msg) = switch t {
    | Warn({warnNumber, details})
    | WarnErr({warnNumber, details}) =>
      let {LocMsg.row: row, column, shortMsg} = details
      let msg = `(Warning number ${warnNumber->Int.toString}) ${shortMsg}`
      (row, column, msg)
    }

    `[1;31m[${prefix}] Line ${row->Int.toString}, ${column->Int.toString}:[0m ${msg}`
  }
}

module WarningFlag = {
  type t = {
    msg: string,
    warn_flags: string,
    warn_error_flags: string,
  }

  let decode = (json): t => {
    open Json.Decode
    {
      msg: field("msg", string, json),
      warn_flags: field("warn_flags", string, json),
      warn_error_flags: field("warn_error_flags", string, json),
    }
  }
}

module TypeHint = {
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

  let decodePosition = json => {
    open Json.Decode
    {
      line: field("line", int, json),
      col: field("col", int, json),
    }
  }

  let decode = (json): t => {
    open Json.Decode
    let data = {
      start: field("start", decodePosition, json),
      end: field("end", decodePosition, json),
      hint: field("hint", string, json),
    }

    switch field("kind", string, json) {
    | "expression" => Expression(data)
    | "type_declaration" => TypeDeclaration(data)
    | "binding" => Binding(data)
    | "core_type" => CoreType(data)
    | other => raise(DecodeError(`Unknown kind "${other}" type hint`))
    }
  }
}

module CompileSuccess = {
  type t = {
    @as("js_code")
    jsCode: string,
    warnings: array<Warning.t>,
    @as("type_hints")
    typeHints: array<TypeHint.t>,
    time: float, // total compilation time
  }

  let decode = (~time: float, json): t => {
    open Json.Decode
    {
      jsCode: field("js_code", string, json),
      warnings: field("warnings", array(Warning.decode, ...), json),
      typeHints: withDefault([], field("type_hints", array(TypeHint.decode, ...), ...), json),
      time,
    }
  }
}

module ConvertSuccess = {
  type t = {
    code: string,
    fromLang: Lang.t,
    toLang: Lang.t,
  }

  let decode = (json): t => {
    open Json.Decode
    {
      code: field("code", string, json),
      fromLang: field("fromLang", Lang.decode, json),
      toLang: field("toLang", Lang.decode, json),
    }
  }
}

module CompileFail = {
  type t =
    | SyntaxErr(array<LocMsg.t>)
    | TypecheckErr(array<LocMsg.t>)
    | WarningErr(array<Warning.t>)
    | WarningFlagErr(WarningFlag.t)
    | OtherErr(array<LocMsg.t>)

  let decode = (json): t => {
    open! Json.Decode

    switch field("type", string, json) {
    | "syntax_error" =>
      let locMsgs = field("errors", array(LocMsg.decode, ...), json)
      // TODO: There seems to be a bug in the ReScript bundle that reports
      //       back multiple LocMsgs of the same value
      locMsgs->LocMsg.dedupe->SyntaxErr
    | "type_error" =>
      let locMsgs = field("errors", array(LocMsg.decode, ...), json)
      TypecheckErr(locMsgs)
    | "warning_error" =>
      let warnings = field("errors", array(Warning.decode, ...), json)
      WarningErr(warnings)
    | "other_error" =>
      let locMsgs = field("errors", array(LocMsg.decode, ...), json)
      OtherErr(locMsgs)

    | "warning_flag_error" =>
      let warningFlag = WarningFlag.decode(json)
      WarningFlagErr(warningFlag)
    | other => raise(DecodeError(`Unknown type "${other}" in CompileFail result`))
    }
  }
}

module CompilationResult = {
  type t =
    | Fail(CompileFail.t) // When a compilation failed with some error result
    | Success(CompileSuccess.t)
    | UnexpectedError(string) // Errors that slip through as uncaught exceptions of the compiler bundle
    | Unknown(string, JSON.t)

  // TODO: We might change this specific api completely before launching
  let decode = (~time: float, json: JSON.t): t => {
    open! Json.Decode

    try switch field("type", string, json) {
    | "success" => Success(CompileSuccess.decode(~time, json))
    | "unexpected_error" => UnexpectedError(field("msg", string, json))
    | _ => Fail(CompileFail.decode(json))
    } catch {
    | DecodeError(errMsg) => Unknown(errMsg, json)
    }
  }
}

module ConversionResult = {
  type t =
    | Success(ConvertSuccess.t)
    | Fail({fromLang: Lang.t, toLang: Lang.t, details: array<LocMsg.t>}) // When a compilation failed with some error result
    | UnexpectedError(string) // Errors that slip through as uncaught exceptions within the playground
    | Unknown(string, JSON.t)

  let decode = (~fromLang: Lang.t, ~toLang: Lang.t, json): t => {
    open! Json.Decode
    try switch field("type", string, json) {
    | "success" => Success(ConvertSuccess.decode(json))
    | "unexpected_error" => UnexpectedError(field("msg", string, json))
    | "syntax_error" =>
      let locMsgs = field("errors", array(LocMsg.decode, ...), json)
      Fail({fromLang, toLang, details: locMsgs})
    | other => Unknown(`Unknown conversion result type "${other}"`, json)
    } catch {
    | DecodeError(errMsg) => Unknown(errMsg, json)
    }
  }
}

module Config = {
  type t = {
    module_system: string,
    warn_flags: string,
    uncurried?: bool,
    open_modules?: array<string>,
  }
}

module Compiler = {
  type t

  // Factory
  @val @scope("rescript_compiler") external make: unit => t = "make"

  @get external version: t => string = "version"

  /*
      Res compiler actions
 */
  @get @scope("rescript") external resVersion: t => string = "version"

  @send @scope("rescript")
  external resCompile: (t, string) => JSON.t = "compile"

  let resCompile = (t, code): CompilationResult.t => {
    let startTime = now()
    let json = resCompile(t, code)
    let stopTime = now()

    CompilationResult.decode(~time=stopTime -. startTime, json)
  }

  @send @scope("rescript")
  external resFormat: (t, string) => JSON.t = "format"

  let resFormat = (t, code): ConversionResult.t => {
    let json = resFormat(t, code)
    ConversionResult.decode(~fromLang=Res, ~toLang=Res, json)
  }

  @send @scope("reason")
  external reasonCompile: (t, string) => JSON.t = "compile"
  let reasonCompile = (t, code): CompilationResult.t => {
    let startTime = now()
    let json = reasonCompile(t, code)
    let stopTime = now()

    CompilationResult.decode(~time=stopTime -. startTime, json)
  }

  @send @scope("reason")
  external reasonFormat: (t, string) => JSON.t = "format"

  let reasonFormat = (t, code): ConversionResult.t => {
    let json = reasonFormat(t, code)
    ConversionResult.decode(~fromLang=Reason, ~toLang=Reason, json)
  }

  @get external ocaml: t => option<dict<string>> = "ocaml"

  let ocamlVersion = (t: t): option<string> => {
    switch ocaml(t) {
    | Some(ocaml) => ocaml->Dict.get("version")
    | None => None
    }
  }

  @send external getConfig: t => Config.t = "getConfig"

  @send external setFilename: (t, string) => bool = "setFilename"

  @send
  external setModuleSystem: (t, [#es6 | #nodejs]) => bool = "setModuleSystem"

  @send external setWarnFlags: (t, string) => bool = "setWarnFlags"

  @send external setOpenModules: (t, array<string>) => bool = "setOpenModules"

  let setConfig = (t: t, config: Config.t): unit => {
    let moduleSystem = switch config.module_system {
    | "commonjs" => #nodejs->Some
    | "esmodule" => #es6->Some
    | _ => None
    }

    Option.forEach(moduleSystem, moduleSystem => t->setModuleSystem(moduleSystem)->ignore)
    Option.forEach(config.open_modules, modules => t->setOpenModules(modules)->ignore)

    t->setWarnFlags(config.warn_flags)->ignore
  }

  @send
  external convertSyntax: (t, string, string, string) => JSON.t = "convertSyntax"

  // General format function
  let convertSyntax = (~fromLang: Lang.t, ~toLang: Lang.t, ~code: string, t): ConversionResult.t =>
    // TODO: There is an issue where trying to convert an empty Reason code
    //       to ReScript code would throw an unhandled JSOO exception
    //       we'd either need to special case the empty Reason code parsing,
    //       or handle the error on the JSOO bundle side more gracefully
    try convertSyntax(t, Lang.toExt(fromLang), Lang.toExt(toLang), code)->ConversionResult.decode(
      ~fromLang,
      ~toLang,
    ) catch {
    | Exn.Error(obj) =>
      switch Exn.message(obj) {
      | Some(m) => ConversionResult.UnexpectedError(m)
      | None => UnexpectedError("")
      }
    }
}

@val @scope("rescript_compiler")
external apiVersion: string = "api_version"
