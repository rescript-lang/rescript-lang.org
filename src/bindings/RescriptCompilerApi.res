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
    open JSON
    switch json {
    | String("re") => Reason
    | String("res") => Res
    | other => throw(Failure(`Unknown language "${other->stringify}". ${__LOC__}`))
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
    open JSON
    switch json {
    | Object(dict{
        "fullMsg": String(fullMsg),
        "shortMsg": String(shortMsg),
        "row": Number(row),
        "column": Number(column),
        "endRow": Number(endRow),
        "endColumn": Number(endColumn),
      }) => {
        fullMsg,
        shortMsg,
        row: row->Float.toInt,
        column: column->Float.toInt,
        endRow: endRow->Float.toInt,
        endColumn: endColumn->Float.toInt,
      }
    | _ => throw(Failure(`Failed to decode LocMsg. ${__LOC__}`))
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
    open JSON
    let warnNumber = switch json {
    | Object(dict{"warnNumber": Number(warnNumber)}) => warnNumber->Float.toInt
    | _ => throw(Failure(`Failed to decode warn number. ${__LOC__}`))
    }
    let details = LocMsg.decode(json)

    switch json {
    | Object(dict{"isError": Boolean(isError)}) =>
      isError ? WarnErr({warnNumber, details}) : Warn({warnNumber, details})
    | _ => throw(Failure(`Failed to decode warnings. ${__LOC__}`))
    }
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
    open JSON
    switch json {
    | Object(dict{
        "msg": String(msg),
        "warn_flags": String(warn_flags),
        "warn_error_flags": String(warn_error_flags),
      }) => {msg, warn_flags, warn_error_flags}
    | _ => throw(Failure(`Failed to decode WarningFlag. ${__LOC__}`))
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
    open JSON
    switch json {
    | Object(dict{"line": Number(line), "col": Number(col)}) => {
        line: line->Float.toInt,
        col: col->Float.toInt,
      }
    | _ => throw(Failure(`Failed to decode position. ${__LOC__}`))
    }
  }

  let decode = (json): t => {
    open JSON
    let data = switch json {
    | Object(dict{"start": startPosition, "end": endPosition, "hint": String(hint)}) => {
        start: decodePosition(startPosition),
        end: decodePosition(endPosition),
        hint,
      }
    | _ => throw(Failure(`Failed to decode type hint position. ${__LOC__}`))
    }

    switch json {
    | Object(dict{"kind": String(kind)}) =>
      switch kind {
      | "expression" => Expression(data)
      | "type_declaration" => TypeDeclaration(data)
      | "binding" => Binding(data)
      | "core_type" => CoreType(data)
      | other => throw(Failure(`Unknown kind "${other}" type hint. ${__LOC__}`))
      }
    | _ => throw(Failure(`Failed to decode type hint kind. ${__LOC__}`))
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
    open JSON
    switch json {
    | Object(dict{
        "js_code": String(jsCode),
        "warnings": Array(warnings),
        "type_hints": Array(typeHints),
      }) =>
      let warnings = warnings->Array.map(Warning.decode)
      let typeHints = typeHints->Array.map(TypeHint.decode)
      {jsCode, warnings, typeHints, time}
    | _ => throw(Failure(`Failed to decode CompileSuccess. ${__LOC__}`))
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
    open JSON
    switch json {
    | Object(dict{"code": String(code), "fromLang": fromLang, "toLang": toLang}) => {
        code,
        fromLang: fromLang->Lang.decode,
        toLang: toLang->Lang.decode,
      }
    | _ => throw(Failure(`Failed to decode ConvertSuccess. ${__LOC__}`))
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
    open JSON
    switch json {
    | String(type_) =>
      switch type_ {
      | "syntax_error" =>
        let locMsgs = switch json {
        | Object(dict{"erros": Array(errors)}) => errors->Array.map(LocMsg.decode)
        | _ => throw(Failure(`Failed to decode erros from syntax_error. ${__LOC__}`))
        }
        // TODO: There seems to be a bug in the ReScript bundle that reports
        //       back multiple LocMsgs of the same value
        locMsgs->LocMsg.dedupe->SyntaxErr
      | "type_error" =>
        let locMsgs = switch json {
        | Object(dict{"erros": Array(errors)}) => errors->Array.map(LocMsg.decode)
        | _ => throw(Failure(`Failed to decode erros from type_error. ${__LOC__}`))
        }
        TypecheckErr(locMsgs)
      | "warning_error" =>
        let warnings = switch json {
        | Object(dict{"erros": Array(warnings)}) => warnings->Array.map(Warning.decode)
        | _ => throw(Failure(`Failed to decode errors from warning_error. ${__LOC__}`))
        }
        WarningErr(warnings)
      | "other_error" =>
        let locMsgs = switch json {
        | Object(dict{"erros": Array(errors)}) => errors->Array.map(LocMsg.decode)
        | _ => throw(Failure(`Failed to decode errors from other_error. ${__LOC__}`))
        }
        OtherErr(locMsgs)

      | "warning_flag_error" => WarningFlagErr(WarningFlag.decode(json))
      | other => throw(Failure(`Unknown type "${other}" in CompileFail result. ${__LOC__}`))
      }
    | _ => throw(Failure(`Failed to decode CompileFail. ${__LOC__}`))
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
    open JSON
    switch json {
    | Object(dict{"type": String(type_)}) =>
      switch type_ {
      | "success" => Success(CompileSuccess.decode(~time, json))
      | "unexpected_error" =>
        switch json {
        | Object(dict{"msg": String(msg)}) => UnexpectedError(msg)
        | _ => throw(Failure(`Failed to decode msg from unexpected_error. ${__LOC__}`))
        }
      | _ => Fail(CompileFail.decode(json))
      }
    | _ => throw(Failure(`Failed to decode CompilationResult. ${__LOC__}`))
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
    open JSON
    switch json {
    | Object(dict{
        "type": String(type_),
        "msg": ?Some(String(msg)),
        "errors": ?Some(Array(errors)),
      }) =>
      switch type_ {
      | "success" => Success(ConvertSuccess.decode(json))
      | "unexpected_error" => msg->UnexpectedError
      | "syntax_error" =>
        let locMsgs = errors->Array.map(LocMsg.decode)
        Fail({fromLang, toLang, details: locMsgs})
      | other => Unknown(`Unknown conversion result type "${other}"`, json)
      }
    | _ => throw(Failure(`Failed to decode ConversionResult. ${__LOC__}`))
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
    | JsExn(obj) =>
      switch JsExn.message(obj) {
      | Some(m) => ConversionResult.UnexpectedError(m)
      | None => UnexpectedError("")
      }
    }
}

@val @scope("rescript_compiler")
external apiVersion: string = "api_version"
