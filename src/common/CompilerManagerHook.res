/*
    This module is intended to manage following things:
    - Loading available versions of bs-platform-js releases
    - Loading actual bs-platform-js bundles on demand
    - Loading third-party libraries together with the compiler bundle
    - Sending data back and forth between consumer and compiler

    The interface is defined with a finite state and action dispatcher.
 */

open RescriptCompilerApi

module LoadScript = {
  type err

  @module("../ffi/loadScript")
  external loadScript: (
    ~src: string,
    ~onSuccess: unit => unit,
    ~onError: err => unit,
  ) => unit => unit = "default"

  @module("../ffi/loadScript")
  external removeScript: (~src: string) => unit = "removeScript"

  let loadScriptPromise = (url: string) => {
    Promise.make((resolve, _) => {
      loadScript(
        ~src=url,
        ~onSuccess=() => resolve(Ok()),
        ~onError=_err => resolve(Error(`Could not load script: ${url}`)),
      )->ignore
    })
  }
}

module CdnMeta = {
  let baseUrl =
    Node.Process.Env.nodeEnv === "development"
      ? "https://cdn.rescript-lang.org"
      : "" + "/playground-bundles"

  let getCompilerUrl = (version): string => `${baseUrl}/${Semver.toString(version)}/compiler.js`

  let getLibraryCmijUrl = (version, libraryName: string): string =>
    `${baseUrl}/${Semver.toString(version)}/${libraryName}/cmij.js`

  let getStdlibRuntimeUrl = (version, filename) =>
    `${baseUrl}/${Semver.toString(version)}/compiler-builtins/stdlib/${filename}`
}

module FinalResult = {
  /* A final result is the last operation the compiler has done, right now this includes... */
  type t =
    | Conv(ConversionResult.t)
    | Comp(CompilationResult.t)
    | Nothing
}

// This will a given list of libraries to a specific target version of the compiler.
// E.g. starting from v9, @rescript/react instead of reason-react is used.
// If the version can't be parsed, an empty array will be returned.
let getLibrariesForVersion = (~version: Semver.t): array<string> => {
  let libraries = if version.major >= 9 {
    ["@rescript/react"]
  } else if version.major < 9 {
    ["reason-react"]
  } else {
    []
  }

  // Since version 11, we ship the compiler-builtins as a separate file
  if version.major >= 11 {
    libraries->Array.push("compiler-builtins")
  }

  // From version 11 to 12.0.0-alpha.3 @rescript/core is an external package
  switch version {
  | {major: 11}
  | {major: 12, minor: 0, patch: 0, preRelease: Some(Alpha(1 | 2 | 3))} =>
    libraries->Array.push("@rescript/core")
  | _ => ()
  }

  libraries
}

let getOpenModules = (~apiVersion: Version.t, ~libraries: array<string>): option<array<string>> =>
  switch apiVersion {
  | V1 | V2 | V3 | UnknownVersion(_) => None
  | V4 | V5 => libraries->Array.some(el => el === "@rescript/core") ? Some(["RescriptCore"]) : None
  }

/*
    This function loads the compiler, plus a defined set of libraries that are available
    on our bs-platform-js-releases channel.

    Due to JSOO specifics, even if we already loaded a compiler before, we need to make sure
    to load the compiler bundle first, and then load the library cmij files right after that.

    If you don't respect the loading order, then the loaded cmij files will not hook into the
    jsoo filesystem and the compiler won't be able to find the cmij content.

    We coupled the compiler / library loading to prevent ppl to try loading compiler / cmij files
    separately and cause all kinds of race conditions.
 */
let attachCompilerAndLibraries = async (~version, ~libraries: array<string>, ()): result<
  unit,
  array<string>,
> => {
  let compilerUrl = CdnMeta.getCompilerUrl(version)

  // Useful for debugging our local build
  /* let compilerUrl = "/linked-bs-bundle.js"; */

  switch await LoadScript.loadScriptPromise(compilerUrl) {
  | Error(_) => Error([`Could not load compiler from url ${compilerUrl}`])
  | Ok(_) =>
    let promises = Array.map(libraries, async lib => {
      let cmijUrl = CdnMeta.getLibraryCmijUrl(version, lib)
      switch await LoadScript.loadScriptPromise(cmijUrl) {
      | Error(_) => Error(`Could not load cmij from url ${cmijUrl}`)
      | r => r
      }
    })

    let all = await Promise.all(promises)

    let errors = Array.filterMap(all, r => {
      switch r {
      | Error(msg) => Some(msg)
      | _ => None
      }
    })

    switch errors {
    | [] => Ok()
    | errs => Error(errs)
    }
  }
}

let wrapReactApp = code =>
  `(function () {
  ${code}
  window.reactRoot.render(React.createElement(App.make, {}));
})();`

let capitalizeFirstLetter = string => {
  let firstLetter = string->String.charAt(0)->String.toUpperCase
  `${firstLetter}${string->String.sliceToEnd(~start=1)}`
}

type error =
  | SetupError(string)
  | CompilerLoadingError(string)

type selected = {
  id: Semver.t, // The id used for loading the compiler bundle (ideally should be the same as compilerVersion)
  apiVersion: Version.t, // The playground API version in use
  compilerVersion: string,
  ocamlVersion: option<string>,
  libraries: array<string>,
  config: Config.t,
  instance: Compiler.t,
}

type ready = {
  code: string,
  versions: array<Semver.t>,
  selected: selected,
  targetLang: Lang.t,
  errors: array<string>, // For major errors like bundle loading
  result: FinalResult.t,
  autoRun: bool,
  validReactCode: bool,
  logs: array<ConsolePanel.log>,
}

type state =
  | Init
  | SetupFailed(string)
  | SwitchingCompiler(ready, Semver.t) // (ready, targetId, libraries)
  | Ready(ready)
  | Compiling({state: ready, previousJsCode: option<string>})
  | Executing({state: ready, jsCode: string})

type action =
  | SwitchToCompiler(Semver.t) // id
  | SwitchLanguage({lang: Lang.t, code: string})
  | Format(string)
  | CompileCode(Lang.t, string)
  | UpdateConfig(Config.t)
  | AppendLog(ConsolePanel.log)
  | ToggleAutoRun
  | RunCode

let createUrl = (pathName, ready) => {
  let params = switch ready.targetLang {
  | Res => []
  | lang => [("ext", RescriptCompilerApi.Lang.toExt(lang))]
  }
  Array.push(params, ("version", "v" ++ ready.selected.compilerVersion))
  Array.push(params, ("module", ready.selected.config.module_system))
  Array.push(params, ("code", ready.code->encodeURIComponent))
  let querystring = params->Array.map(((key, value)) => key ++ "=" ++ value)->Array.join("&")
  let url = pathName ++ "?" ++ querystring
  url
}

let defaultModuleSystem = "esmodule"

// ~initialLang:
// The target language the compiler should be set to during
// playground initialization.  If the compiler doesn't support the language, it
// will default to ReScript syntax

// ~onAction:
//  This function is especially useful if you want to maintain state that
//  depends on any action happening in the compiler, no matter if a state
//  transition happened, or not.  We need that for a ActivityIndicator
//  component to give feedback to the user that an action happened (useful in
//  cases where the output didn't visually change)
let useCompilerManager = (
  ~initialVersion: option<Semver.t>=?,
  ~initialModuleSystem=defaultModuleSystem,
  ~initialLang: Lang.t=Res,
  ~onAction: option<action => unit>=?,
  ~versions: array<Semver.t>,
  (),
) => {
  let (state, setState) = React.useState(_ => Init)
  let router = Next.Router.useRouter()

  // Dispatch method for the public interface
  let dispatch = (action: action): unit => {
    Option.forEach(onAction, cb => cb(action))
    setState(state =>
      switch action {
      | SwitchToCompiler(id) =>
        switch state {
        | Ready(ready) if ready.selected.id !== id =>
          // TODO: Check if libraries have changed as well
          SwitchingCompiler(ready, id)
        | _ => state
        }
      | UpdateConfig(config) =>
        switch state {
        | Ready(ready) =>
          ready.selected.instance->Compiler.setConfig(config)
          let selected = {...ready.selected, config}
          Compiling({state: {...ready, selected}, previousJsCode: None})
        | _ => state
        }
      | CompileCode(lang, code) =>
        switch state {
        | Ready(ready) =>
          Compiling({
            state: {...ready, code, targetLang: lang},
            previousJsCode: switch ready.result {
            | Comp(Success({jsCode})) => Some(jsCode)
            | _ => None
            },
          })
        | _ => state
        }
      | SwitchLanguage({lang, code}) =>
        switch state {
        | Ready(ready) =>
          let instance = ready.selected.instance
          let availableTargetLangs = Version.availableLanguages(ready.selected.apiVersion)

          let currentLang = ready.targetLang

          Array.find(availableTargetLangs, l => l === lang)
          ->Option.map(lang => {
            // Try to automatically transform code
            let (result, targetLang) = switch ready.selected.apiVersion {
            | V1 =>
              let convResult = switch (currentLang, lang) {
              | (Reason, Res) =>
                instance->Compiler.convertSyntax(~fromLang=Reason, ~toLang=Res, ~code)->Some
              | (Res, Reason) =>
                instance->Compiler.convertSyntax(~fromLang=Res, ~toLang=Reason, ~code)->Some
              | _ => None
              }

              /*
                    Syntax convertion works the following way:
                    If currentLang -> otherLang is not valid, try to pretty print the code
                    with the otherLang, in case we e.g. want to copy paste or otherLang code
                    in the editor and quickly switch to it
 */
              switch convResult {
              | Some(result) =>
                switch result {
                | ConversionResult.Fail(_)
                | Unknown(_, _)
                | UnexpectedError(_) =>
                  let secondTry =
                    instance->Compiler.convertSyntax(~fromLang=lang, ~toLang=lang, ~code)
                  switch secondTry {
                  | ConversionResult.Fail(_)
                  | Unknown(_, _)
                  | UnexpectedError(_) => (FinalResult.Conv(secondTry), lang)
                  | Success(_) => (Conv(secondTry), lang)
                  }
                | ConversionResult.Success(_) => (Conv(result), lang)
                }
              | None => (Nothing, lang)
              }
            | _ => (Nothing, lang)
            }

            Ready({...ready, result, errors: [], targetLang})
          })
          ->Option.getOr(state)
        | _ => state
        }
      | Format(code) =>
        switch state {
        | Ready(ready) =>
          let instance = ready.selected.instance
          let convResult = switch ready.targetLang {
          | Res => instance->Compiler.resFormat(code)->Some
          | Reason => instance->Compiler.reasonFormat(code)->Some
          }

          let result = switch convResult {
          | Some(result) =>
            switch result {
            | ConversionResult.Success(success) =>
              // We will only change the result to a ConversionResult
              // in case the reformatting has actually changed code
              // otherwise we'd loose previous compilationResults, although
              // the result should be the same anyways
              if code !== success.code {
                FinalResult.Conv(result)
              } else {
                ready.result
              }
            | ConversionResult.Fail(_)
            | Unknown(_, _)
            | UnexpectedError(_) =>
              FinalResult.Conv(result)
            }
          | None => ready.result
          }

          Ready({...ready, result, errors: []})
        | _ => state
        }
      | AppendLog(log) =>
        switch state {
        | Ready(ready) => Ready({...ready, logs: Array.concat(ready.logs, [log])})
        | _ => state
        }
      | ToggleAutoRun =>
        switch state {
        | Ready({autoRun: true} as ready) => Ready({...ready, autoRun: false})
        | Ready({autoRun: false} as ready) =>
          Compiling({
            state: {
              ...ready,
              autoRun: true,
            },
            previousJsCode: switch ready.result {
            | Comp(Success({jsCode})) => Some(jsCode)
            | _ => None
            },
          })
        | _ => state
        }
      | RunCode =>
        switch state {
        | Ready({result: Comp(Success({jsCode}))} as ready) =>
          Executing({state: {...ready, autoRun: false}, jsCode})
        | _ => state
        }
      }
    )
  }

  let dispatchError = (err: error) =>
    setState(prev => {
      let msg = switch err {
      | SetupError(msg) => msg
      | CompilerLoadingError(msg) => msg
      }
      switch prev {
      | Ready(ready) => Ready({...ready, errors: Array.concat(ready.errors, [msg])})
      | _ => SetupFailed(msg)
      }
    })

  React.useEffect(() => {
    let updateState = async () => {
      switch state {
      | Init =>
        switch versions {
        | [] => dispatchError(SetupError("No compiler versions found"))
        | versions =>
          switch initialVersion {
          | Some(version) =>
            // Latest version is already running on @rescript/react
            let libraries = getLibrariesForVersion(~version)

            switch await attachCompilerAndLibraries(~version, ~libraries, ()) {
            | Ok() =>
              let instance = Compiler.make()
              let apiVersion = apiVersion->Version.fromString
              let open_modules = getOpenModules(~apiVersion, ~libraries)

              // Note: The compiler bundle currently defaults to
              // commonjs when initiating the compiler, but our playground
              // should default to esmodule. So we override the config
              // and use the `setConfig` function to sync up the
              // internal compiler state with our playground state.
              let config = {
                ...instance->Compiler.getConfig,
                module_system: initialModuleSystem,
                ?open_modules,
              }
              instance->Compiler.setConfig(config)

              let selected = {
                id: version,
                apiVersion,
                compilerVersion: instance->Compiler.version,
                ocamlVersion: instance->Compiler.ocamlVersion,
                config,
                libraries,
                instance,
              }

              let targetLang =
                Version.availableLanguages(apiVersion)
                ->Array.find(l => l === initialLang)
                ->Option.getOr(Version.defaultTargetLang)

              setState(_ => Ready({
                code: "",
                selected,
                targetLang,
                versions,
                errors: [],
                result: FinalResult.Nothing,
                logs: [],
                autoRun: false,
                validReactCode: false,
              }))
            | Error(errs) =>
              let msg = Array.join(errs, "; ")

              dispatchError(CompilerLoadingError(msg))
            }
          | None => dispatchError(CompilerLoadingError("Cant not found the initial version"))
          }
        }
      | SwitchingCompiler(ready, version) =>
        let libraries = getLibrariesForVersion(~version)

        switch await attachCompilerAndLibraries(~version, ~libraries, ()) {
        | Ok() =>
          // Make sure to remove the previous script from the DOM as well
          LoadScript.removeScript(~src=CdnMeta.getCompilerUrl(ready.selected.id))

          // We are removing the previous libraries, therefore we use ready.selected here
          Array.forEach(ready.selected.libraries, lib =>
            LoadScript.removeScript(~src=CdnMeta.getLibraryCmijUrl(ready.selected.id, lib))
          )

          let instance = Compiler.make()
          let apiVersion = apiVersion->Version.fromString
          let open_modules = getOpenModules(~apiVersion, ~libraries)

          let config = {
            ...instance->Compiler.getConfig,
            module_system: defaultModuleSystem,
            ?open_modules,
          }
          instance->Compiler.setConfig(config)

          let selected = {
            id: version,
            apiVersion,
            compilerVersion: instance->Compiler.version,
            ocamlVersion: instance->Compiler.ocamlVersion,
            config,
            libraries,
            instance,
          }

          setState(_ => Ready({
            code: ready.code,
            selected,
            targetLang: Version.defaultTargetLang,
            versions: ready.versions,
            errors: [],
            result: FinalResult.Nothing,
            autoRun: ready.autoRun,
            validReactCode: ready.validReactCode,
            logs: [],
          }))
        | Error(errs) =>
          let msg = Array.join(errs, "; ")

          dispatchError(CompilerLoadingError(msg))
        }
      | Compiling({state: {targetLang: lang, code, autoRun} as ready}) =>
        let apiVersion = ready.selected.apiVersion
        let instance = ready.selected.instance

        let compResult = switch apiVersion {
        | V1 =>
          switch lang {
          | Lang.Reason => instance->Compiler.reasonCompile(code)
          | Lang.Res => instance->Compiler.resCompile(code)
          }
        | V2 | V3 | V4 =>
          switch lang {
          | Lang.Reason =>
            CompilationResult.UnexpectedError(
              `Reason not supported with API version "${apiVersion->RescriptCompilerApi.Version.toString}"`,
            )
          | Lang.Res => instance->Compiler.resCompile(code)
          }
        | V5 =>
          switch lang {
          | Lang.Res => instance->Compiler.resCompile(code)
          | _ => CompilationResult.UnexpectedError(`Can't handle with lang: ${lang->Lang.toString}`)
          }
        | UnknownVersion(version) =>
          CompilationResult.UnexpectedError(
            `Can't handle result of compiler API version "${version}"`,
          )
        }
        let ready = {...ready, result: FinalResult.Comp(compResult)}
        setState(_ =>
          switch (ready.result, autoRun) {
          | (FinalResult.Comp(Success({jsCode})), true) => Executing({state: ready, jsCode})
          | _ => Ready(ready)
          }
        )
      | Executing({state, jsCode}) =>
        open Babel

        let ast = Parser.parse(jsCode, {sourceType: "module"})
        let {entryPointExists, code, imports} = PlaygroundValidator.validate(ast)
        let imports = imports->Dict.mapValues(path => {
          let filename = path->String.sliceToEnd(~start=9) // the part after "./stdlib/"
          let filename = switch state.selected.id {
          | {major: 12, minor: 0, patch: 0, preRelease: Some(Alpha(alpha))} if alpha < 8 =>
            let filename = if filename->String.startsWith("core__") {
              filename->String.sliceToEnd(~start=6)
            } else {
              filename
            }
            capitalizeFirstLetter(filename)
          | {major} if major < 12 && filename->String.startsWith("core__") =>
            capitalizeFirstLetter(filename)
          | _ => filename
          }
          let compilerVersion = switch state.selected.id {
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
          CdnMeta.getStdlibRuntimeUrl(compilerVersion, filename)
        })

        entryPointExists
          ? code->wrapReactApp->EvalIFrame.sendOutput(imports)
          : EvalIFrame.sendOutput(code, imports)
        setState(_ => Ready({...state, logs: [], validReactCode: entryPointExists}))
      | SetupFailed(_) => ()
      | Ready(ready) =>
        let url = createUrl(router.route, ready)
        WebAPI.History.replaceState(history, ~data=JSON.Null, ~unused="", ~url)
      }
    }

    updateState()->Promise.ignore
    None
  }, (
    state,
    dispatchError,
    initialVersion,
    initialModuleSystem,
    initialLang,
    versions,
    router.route,
  ))

  (state, dispatch)
}
