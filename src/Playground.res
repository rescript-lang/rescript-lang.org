open CompilerManagerHook
module Api = RescriptCompilerApi

type layout = Column | Row
type tab = JavaScript | Output | Problems | Settings

module JsxCompilation = {
  type t =
    | Plain
    | PreserveJsx

  let getLabel = (mode: t): string =>
    switch mode {
    | Plain => "Plain JS functions"
    | PreserveJsx => "Preserve JSX"
    }

  let toBool = (mode: t): bool =>
    switch mode {
    | Plain => false
    | PreserveJsx => true
    }

  let fromBool = (bool): t => bool ? PreserveJsx : Plain
}

module ExperimentalFeatures = {
  type t = LetUnwrap

  let getLabel = (feature: t): string =>
    switch feature {
    | LetUnwrap => "let?"
    }

  let list = [LetUnwrap]
}

let breakingPoint = 1024

module DropdownSelect = {
  @react.component
  let make = (~onChange, ~name, ~value, ~disabled=false, ~children) => {
    let opacity = disabled ? " opacity-50" : ""
    <select
      className={"text-14 bg-gray-100 border border-gray-80 inline-block rounded px-4 py-1 font-semibold" ++
      opacity}
      name
      value
      disabled
      onChange
    >
      children
    </select>
  }
}

module SelectionOption = {
  @react.component
  let make = (~label, ~isActive, ~disabled, ~onClick) => {
    <button
      className={"mr-1 px-2 py-1 rounded inline-block " ++ if isActive {
        "bg-fire text-white font-bold"
      } else {
        "bg-gray-80 opacity-50 hover:opacity-80"
      }}
      onClick
      disabled
    >
      {React.string(label)}
    </button>
  }
}

module ToggleSelection = {
  @react.component
  let make = (
    ~onChange: 'a => unit,
    ~values: array<'a>,
    ~toLabel: 'a => string,
    ~selected: 'a,
    ~disabled=false,
  ) => {
    // We make sure that there's at least one element in the array
    // otherwise we run into undefined behavior
    let values = if Array.length(values) === 0 {
      [selected]
    } else {
      values
    }

    <div className={(disabled ? "opacity-25" : "") ++ "flex w-full"}>
      {values
      ->Array.map(value => {
        let label = toLabel(value)
        let isActive = value === selected
        let onClick = _event => {
          if !isActive {
            onChange(value)
          }
        }

        <SelectionOption key={label} label isActive onClick disabled />
      })
      ->React.array}
    </div>
  }
}

module ResultPane = {
  module PreWrap = {
    @react.component
    let make = (~className="", ~children) =>
      <pre className={"whitespace-pre-wrap " ++ className}> children </pre>
  }
  type prefix = [#W | #E]
  let compactErrorLine = (~highlight=false, ~prefix: prefix, locMsg: Api.LocMsg.t) => {
    let {Api.LocMsg.row: row, column, shortMsg} = locMsg
    let prefixColor = switch prefix {
    | #W => "text-orange"
    | #E => "text-fire"
    }

    let prefixText = switch prefix {
    | #W => "[W]"
    | #E => "[E]"
    }

    let highlightClass = switch (highlight, prefix) {
    | (false, _) => ""
    | (true, #W) => "bg-orange-15"
    | (true, #E) => "bg-fire-90 rounded"
    }

    <div className="font-mono mb-4 pb-6 last:mb-0 last:pb-0 last:border-0 border-b border-gray-80 ">
      <div className={"p-2 " ++ highlightClass}>
        <span className=prefixColor> {React.string(prefixText)} </span>
        <span className="font-medium text-gray-40">
          {React.string(` Line ${row->Int.toString}, column ${column->Int.toString}:`)}
        </span>
        <AnsiPre className="whitespace-pre-wrap "> shortMsg </AnsiPre>
      </div>
    </div>
  }

  let isHighlighted = (~focusedRowCol=?, locMsg): bool =>
    switch focusedRowCol {
    | Some(focusedRowCol) =>
      let {Api.LocMsg.row: row, column} = locMsg
      let (fRow, fCol) = focusedRowCol

      fRow === row && fCol === column

    | None => false
    }

  let filterHighlightedLocMsgs = (~focusedRowCol, locMsgs: array<Api.LocMsg.t>): array<
    Api.LocMsg.t,
  > => {
    open Api.LocMsg
    switch focusedRowCol {
    | Some(focusedRowCol) =>
      let (fRow, fCol) = focusedRowCol
      let filtered = Array.filter(locMsgs, locMsg => fRow === locMsg.row && fCol === locMsg.column)

      if Array.length(filtered) === 0 {
        locMsgs
      } else {
        filtered
      }

    | None => locMsgs
    }
  }

  let filterHighlightedLocWarnings = (~focusedRowCol, warnings: array<Api.Warning.t>): array<
    Api.Warning.t,
  > =>
    switch focusedRowCol {
    | Some(focusedRowCol) =>
      let (fRow, fCol) = focusedRowCol
      let filtered = Array.filter(warnings, warning =>
        switch warning {
        | Warn({details})
        | WarnErr({details}) =>
          fRow === details.row && fCol === details.column
        }
      )
      if Array.length(filtered) === 0 {
        warnings
      } else {
        filtered
      }
    | None => warnings
    }

  let renderResult = (
    ~focusedRowCol: option<(int, int)>,
    ~targetLang: Api.Lang.t,
    ~compilerVersion: string,
    result: FinalResult.t,
  ): React.element =>
    switch result {
    | FinalResult.Comp(Fail(result)) =>
      switch result {
      | TypecheckErr(locMsgs)
      | OtherErr(locMsgs)
      | SyntaxErr(locMsgs) =>
        filterHighlightedLocMsgs(~focusedRowCol, locMsgs)
        ->Array.mapWithIndex((locMsg, i) =>
          <div key={Int.toString(i)}>
            {compactErrorLine(
              ~highlight=isHighlighted(~focusedRowCol?, locMsg),
              ~prefix=#E,
              locMsg,
            )}
          </div>
        )
        ->React.array
      | WarningErr(warnings) =>
        filterHighlightedLocWarnings(~focusedRowCol, warnings)
        ->Array.mapWithIndex((warning, i) => {
          let (prefix, details) = switch warning {
          | Api.Warning.Warn({details}) => (#W, details)
          | WarnErr({details}) => (#E, details)
          }
          <div key={Int.toString(i)}>
            {compactErrorLine(~highlight=isHighlighted(~focusedRowCol?, details), ~prefix, details)}
          </div>
        })
        ->React.array
      | WarningFlagErr({msg}) =>
        <div>
          {React.string("There are some issues with your compiler flag configuration:")}
          {React.string(msg)}
        </div>
      }
    | Comp(Success({warnings})) =>
      if Array.length(warnings) === 0 {
        <PreWrap> {React.string("0 Errors, 0 Warnings")} </PreWrap>
      } else {
        filterHighlightedLocWarnings(~focusedRowCol, warnings)
        ->Array.mapWithIndex((warning, i) => {
          let (prefix, details) = switch warning {
          | Api.Warning.Warn({details}) => (#W, details)
          | WarnErr({details}) => (#E, details)
          }
          <div key={Int.toString(i)}>
            {compactErrorLine(~highlight=isHighlighted(~focusedRowCol?, details), ~prefix, details)}
          </div>
        })
        ->React.array
      }
    | Conv(Success({fromLang, toLang})) =>
      let msg = if fromLang === toLang {
        "Formatting completed with 0 errors"
      } else {
        let toStr = Api.Lang.toString(toLang)
        `Switched to ${toStr} with 0 errors`
      }
      <PreWrap> {React.string(msg)} </PreWrap>
    | Conv(Fail({fromLang, toLang, details})) =>
      let errs =
        filterHighlightedLocMsgs(~focusedRowCol, details)
        ->Array.mapWithIndex((locMsg, i) =>
          <div key={Int.toString(i)}>
            {compactErrorLine(
              ~highlight=isHighlighted(~focusedRowCol?, locMsg),
              ~prefix=#E,
              locMsg,
            )}
          </div>
        )
        ->React.array

      // The way the UI is currently designed, there shouldn't be a case where fromLang !== toLang.
      // We keep both cases though in case we change things later
      let msg = if fromLang === toLang {
        let langStr = Api.Lang.toString(toLang)
        `The code is not valid ${langStr} syntax.`
      } else {
        let fromStr = Api.Lang.toString(fromLang)
        let toStr = Api.Lang.toString(toLang)
        `Could not convert from "${fromStr}" to "${toStr}" due to malformed syntax:`
      }
      <div>
        <PreWrap className="text-16 mb-4"> {React.string(msg)} </PreWrap>
        errs
      </div>
    | Comp(UnexpectedError(msg))
    | Conv(UnexpectedError(msg)) =>
      React.string(msg)
    | Comp(Unknown(msg, json))
    | Conv(Unknown(msg, json)) =>
      let subheader = "font-bold text-gray-40 text-16"
      <div>
        <PreWrap>
          {React.string(
            "The compiler bundle API returned a result that couldn't be interpreted. Please open an issue on our ",
          )}
          <Markdown.A href="https://github.com/rescript-lang/rescript-lang.org/issues">
            {React.string("issue tracker")}
          </Markdown.A>
          {React.string(".")}
        </PreWrap>
        <div className="mt-4">
          <PreWrap>
            <div className=subheader> {React.string("Message: ")} </div>
            {React.string(msg)}
          </PreWrap>
        </div>
        <div className="mt-4">
          <PreWrap>
            <span className=subheader> {React.string("Received JSON payload:")} </span>
            <div> {JSON.stringify(json, ~space=2)->React.string} </div>
          </PreWrap>
        </div>
      </div>
    | Nothing =>
      let syntax = Api.Lang.toString(targetLang)
      <PreWrap>
        {React.string(
          `This playground is now running on compiler version ${compilerVersion} with ${syntax} syntax`,
        )}
      </PreWrap>
    }

  let renderTitle = result => {
    let errClass = "text-fire"
    let warnClass = "text-orange"
    let okClass = "text-turtle-dark"

    let (className, text) = switch result {
    | FinalResult.Comp(Fail(result)) =>
      switch result {
      | SyntaxErr(_) => (errClass, "Syntax Errors")
      | TypecheckErr(_) => (errClass, "Type Errors")
      | WarningErr(_) => (warnClass, "Warning Errors")
      | WarningFlagErr(_) => (errClass, "Config Error")
      | OtherErr(_) => (errClass, "Errors")
      }
    | Conv(Fail(_)) => (errClass, "Syntax Errors")
    | Comp(Success({warnings})) =>
      let warningNum = Array.length(warnings)
      if warningNum === 0 {
        (okClass, "Compiled successfully")
      } else {
        (warnClass, "Compiled with " ++ (Int.toString(warningNum) ++ " Warning(s)"))
      }
    | Conv(Success(_)) => (okClass, "Format Successful")
    | Comp(UnexpectedError(_))
    | Conv(UnexpectedError(_)) => (errClass, "Unexpected Error")
    | Comp(Unknown(_))
    | Conv(Unknown(_)) => (errClass, "Unknown Result")
    | Nothing => (okClass, "Ready")
    }

    <span className> {React.string(text)} </span>
  }

  @react.component
  let make = (
    ~targetLang: Api.Lang.t,
    ~compilerVersion: string,
    ~focusedRowCol: option<(int, int)>=?,
    ~result: FinalResult.t,
  ) =>
    <div className="pt-4 bg-0 overflow-y-auto playground-scrollbar">
      <div className="flex items-center text-16 font-medium px-4">
        <div className="pr-4"> {renderTitle(result)} </div>
      </div>
      <div className="">
        <div className="text-gray-20 px-4 py-4">
          {renderResult(~focusedRowCol, ~compilerVersion, ~targetLang, result)}
        </div>
      </div>
    </div>
}

module WarningFlagsWidget = {
  // Inspired by MUI (who got inspired by WAI best practise examples)
  // https://github.com/mui-org/material-ui/blob/next/packages/material-ui-lab/src/useAutocomplete/useAutocomplete.js#L327
  let scrollToElement = (
    ~parent: WebAPI.DOMAPI.htmlElement,
    element: WebAPI.DOMAPI.htmlElement,
  ): unit =>
    if parent.scrollHeight > parent.clientHeight {
      let scrollBottom = parent.clientHeight + Float.toInt(parent.scrollTop)
      let elementBottom = element.offsetTop + element.offsetHeight

      if elementBottom > scrollBottom {
        parent.scrollTop = Float.fromInt(elementBottom - parent.clientHeight)
      } else if element.offsetTop - element.offsetHeight < Float.toInt(parent.scrollTop) {
        parent.scrollTop = Float.fromInt(element.offsetTop - element.offsetHeight)
      }
    }

  type suggestion =
    | NoSuggestion
    | FuzzySuggestions({
        modifier: string, // tells if the user is currently inputting a + / -
        // All tokens without the suggestion token (last one)
        precedingTokens: array<WarningFlagDescription.Parser.token>,
        results: array<(string, string)>,
        selected: int,
      })
    | ErrorSuggestion(string)

  type rec state =
    | HideSuggestion({input: string})
    | ShowTokenHint({lastState: state, token: WarningFlagDescription.Parser.token}) // For restoring the previous state // hover target
    | Typing({suggestion: suggestion, input: string})

  let hide = (prev: state) =>
    switch prev {
    | Typing({input})
    | ShowTokenHint({lastState: Typing({input})}) =>
      HideSuggestion({input: input})
    | ShowTokenHint(_) => HideSuggestion({input: ""})
    | HideSuggestion(_) => prev
    }

  let updateInput = (prev: state, input: string) => {
    let suggestion = switch input {
    | "" => NoSuggestion
    | _ =>
      // Case: +
      let last = input->String.length - 1
      switch input->String.get(last)->Option.getUnsafe {
      | "+" as modifier
      | "-" as modifier =>
        let results = WarningFlagDescription.lookupAll()

        let partial = input->String.substring(~start=0, ~end=last)

        let precedingTokens = switch WarningFlagDescription.Parser.parse(partial) {
        | Ok(tokens) => tokens
        | Error(_) => []
        }

        FuzzySuggestions({
          modifier,
          precedingTokens,
          results,
          selected: 0,
        })
      | _ =>
        // Case: +1...
        let results = WarningFlagDescription.Parser.parse(input)
        switch results {
        | Ok(tokens) =>
          let last = tokens[Array.length(tokens) - 1]

          switch last {
          | Some(token) =>
            let results = WarningFlagDescription.fuzzyLookup(token.flag)
            if Array.length(results) === 0 {
              ErrorSuggestion("No results")
            } else {
              let precedingTokens = Array.slice(tokens, ~start=0, ~end=Array.length(tokens) - 1)
              let modifier = token.enabled ? "+" : "-"
              FuzzySuggestions({
                modifier,
                precedingTokens,
                results,
                selected: 0,
              })
            }
          | None => NoSuggestion
          }
        | Error(msg) =>
          // In case the user started with a + / -
          // show all available flags
          switch input {
          | "+" as modifier
          | "-" as modifier =>
            let results = WarningFlagDescription.lookupAll()

            FuzzySuggestions({
              modifier,
              precedingTokens: [],
              results,
              selected: 0,
            })
          | _ => ErrorSuggestion(msg)
          }
        }
      }
    }

    switch prev {
    | ShowTokenHint(_)
    | Typing(_) =>
      Typing({suggestion, input})
    | HideSuggestion(_) => Typing({suggestion, input})
    }
  }

  let selectPrevious = (prev: state) =>
    switch prev {
    | Typing({suggestion: FuzzySuggestions({selected, results} as suggestion)} as typing) =>
      let nextIdx = if selected > 0 {
        selected - 1
      } else {
        Array.length(results) - 1
      }
      Typing({
        ...typing,
        suggestion: FuzzySuggestions({...suggestion, selected: nextIdx}),
      })
    | ShowTokenHint(_)
    | Typing(_)
    | HideSuggestion(_) => prev
    }

  let selectNext = (prev: state) =>
    switch prev {
    | Typing({suggestion: FuzzySuggestions({selected, results} as suggestion)} as typing) =>
      let nextIdx = if selected < Array.length(results) - 1 {
        selected + 1
      } else {
        0
      }
      Typing({
        ...typing,
        suggestion: FuzzySuggestions({...suggestion, selected: nextIdx}),
      })
    | ShowTokenHint(_)
    | Typing(_)
    | HideSuggestion(_) => prev
    }

  @react.component
  let make = (
    ~onUpdate: array<WarningFlagDescription.Parser.token> => unit,
    ~flags: array<WarningFlagDescription.Parser.token>,
  ) => {
    let (state, setState) = React.useState(_ => HideSuggestion({input: ""}))

    // Used for the suggestion box list
    let listboxRef = React.useRef(Nullable.null)

    // Used for the text input
    let inputRef = React.useRef(Nullable.null)

    let focusInput = () =>
      inputRef.current->Nullable.forEach(el => WebAPI.HTMLInputElement.focus(el))

    let blurInput = () =>
      inputRef.current->Nullable.forEach(el => WebAPI.HTMLInputElement.focus(el))

    let chips = Array.mapWithIndex(flags, (token, i) => {
      let {WarningFlagDescription.Parser.flag: flag, enabled} = token

      let isActive = switch state {
      | ShowTokenHint({token}) => token.flag === flag
      | _ => false
      }

      let full = (enabled ? "+" : "-") ++ flag
      let color = switch (enabled, isActive) {
      | (true, false) => "text-turtle-dark"
      | (false, false) => "text-fire"
      | (true, true) => "bg-gray-40 text-turtle-dark"
      | (false, true) => "bg-gray-40 text-fire"
      }

      let hoverEnabled = switch state {
      | ShowTokenHint(_)
      | Typing(_) => true
      | HideSuggestion(_) => false
      }

      let (onMouseEnter, onMouseLeave) = if hoverEnabled {
        let enter = evt => {
          ReactEvent.Mouse.preventDefault(evt)
          ReactEvent.Mouse.stopPropagation(evt)

          setState(prev => ShowTokenHint({token, lastState: prev}))
        }

        let leave = evt => {
          ReactEvent.Mouse.preventDefault(evt)
          ReactEvent.Mouse.stopPropagation(evt)

          setState(prev =>
            switch prev {
            | ShowTokenHint({lastState}) => lastState
            | _ => prev
            }
          )
        }
        (Some(enter), Some(leave))
      } else {
        (None, None)
      }

      let onClick = evt => {
        // Removes clicked token from the current flags
        ReactEvent.Mouse.preventDefault(evt)

        let remaining = Array.filter(flags, t => t.flag !== flag)
        onUpdate(remaining)
      }

      <span
        onClick
        ?onMouseEnter
        ?onMouseLeave
        className={color ++ " hover:cursor-default text-16 inline-block border border-gray-40 rounded-full px-2 mr-1"}
        key={Int.toString(i) ++ flag}
      >
        {React.string(full)}
      </span>
    })->React.array

    let onKeyDown = evt => {
      let key = ReactEvent.Keyboard.key(evt)
      let ctrlKey = ReactEvent.Keyboard.ctrlKey(evt)

      /* let caretPosition = ReactEvent.Keyboard.target(evt)["selectionStart"] */
      /* Console.log2("caretPosition", caretPosition); */

      let full = (ctrlKey ? "CTRL+" : "") ++ key
      switch full {
      | "Enter" =>
        switch state {
        | Typing({suggestion: FuzzySuggestions({precedingTokens, modifier, selected, results})}) =>
          // In case a selection was made correctly, add
          // the flag to the current flags
          switch results[selected] {
          | Some((num, _)) =>
            let token = {
              WarningFlagDescription.Parser.enabled: modifier === "+",
              flag: num,
            }

            // TODO: merge tokens with flags
            let newTokens = Array.concat(precedingTokens, [token])

            let all = WarningFlagDescription.Parser.merge(flags, newTokens)

            onUpdate(all)
            setState(prev => updateInput(prev, ""))
          | None => ()
          }
        | _ => ()
        }
        ReactEvent.Keyboard.preventDefault(evt)
      | "Escape" => blurInput()
      | "Tab" =>
        switch state {
        | Typing({suggestion: FuzzySuggestions({modifier, precedingTokens, selected, results})}) =>
          switch results[selected] {
          | Some((num, _)) =>
            let flag = modifier ++ num

            let completed = WarningFlagDescription.Parser.tokensToString(precedingTokens) ++ flag
            setState(prev => updateInput(prev, completed))
          | None => ()
          }
          // Prevents tab to change focus
          ReactEvent.Keyboard.preventDefault(evt)
        | _ => ()
        }
      | "ArrowDown"
      | "CTRL+n" =>
        setState(prev => selectNext(prev))
        ReactEvent.Keyboard.preventDefault(evt)
      | "ArrowUp"
      | "CTRL+p" =>
        setState(prev => selectPrevious(prev))
        ReactEvent.Keyboard.preventDefault(evt)
      | "ArrowRight"
      | "ArrowLeft" => ()
      | full =>
        switch state {
        | Typing({suggestion: ErrorSuggestion(_)}) =>
          if full !== "Backspace" {
            ReactEvent.Keyboard.preventDefault(evt)
          }
        | _ => Console.log(full)
        }
      }
    }

    let suggestions = switch state {
    | ShowTokenHint({token}) =>
      WarningFlagDescription.lookup(token.flag)
      ->Array.map(((num, description)) => {
        let (modifier, color) = if token.enabled {
          ("(Enabled) ", "text-turtle-dark")
        } else {
          ("(Disabled) ", "text-fire")
        }

        <div key=num>
          <span className=color> {React.string(modifier)} </span>
          {React.string(description)}
        </div>
      })
      ->React.array
      ->Some
    | Typing(typing) if typing.suggestion != NoSuggestion =>
      let suggestions = switch typing.suggestion {
      | NoSuggestion => React.null
      | ErrorSuggestion(msg) => React.string(msg)
      | FuzzySuggestions({precedingTokens, selected, results, modifier}) =>
        Array.mapWithIndex(results, ((flag, desc), i) => {
          let activeClass = selected === i ? "bg-gray-40" : ""

          let ref = if selected === i {
            ReactDOM.Ref.callbackDomRef(dom => {
              let el = Nullable.toOption(dom)
              let parent = listboxRef.current->Nullable.toOption

              switch (parent, el) {
              | (Some(parent), Some(el)) =>
                Some(() => scrollToElement(~parent, (Obj.magic(el): WebAPI.DOMAPI.htmlElement)))
              | _ => None
              }
            })->Some
          } else {
            None
          }

          let onMouseEnter = evt => {
            ReactEvent.Mouse.preventDefault(evt)
            setState(prev =>
              switch prev {
              | Typing({suggestion: FuzzySuggestions(fuzzySuggestion)}) =>
                Typing({
                  ...typing,
                  suggestion: FuzzySuggestions({...fuzzySuggestion, selected: i}),
                })
              | _ => prev
              }
            )
          }

          let onClick = evt => {
            ReactEvent.Mouse.preventDefault(evt)
            setState(prev =>
              switch prev {
              | Typing(_) =>
                let full = modifier ++ flag
                let completed =
                  WarningFlagDescription.Parser.tokensToString(precedingTokens) ++ full
                updateInput(prev, completed)
              | _ => prev
              }
            )
          }

          <div ?ref onMouseEnter onMouseDown=onClick className=activeClass key=flag>
            {React.string(modifier ++ (flag ++ (": " ++ desc)))}
          </div>
        })->React.array
      }
      Some(suggestions)

    | Typing(_) | HideSuggestion(_) => None
    }

    let suggestionBox =
      Option.map(suggestions, elements =>
        <div
          ref={ReactDOM.Ref.domRef((Obj.magic(listboxRef): React.ref<Nullable.t<Dom.element>>))}
          className="p-2 absolute overflow-auto playground-scrollbar z-50 border-b rounded border-l border-r block w-full bg-gray-100 max-h-60"
        >
          elements
        </div>
      )->Option.getOr(React.null)

    let onChange = evt => {
      ReactEvent.Form.preventDefault(evt)
      let input = ReactEvent.Form.target(evt)["value"]
      setState(prev => updateInput(prev, input))
    }

    let onBlur = evt => {
      ReactEvent.Focus.preventDefault(evt)
      ReactEvent.Focus.stopPropagation(evt)
      setState(prev => hide(prev))
    }

    let onFocus = evt => {
      let input = ReactEvent.Focus.target(evt)["value"]
      setState(prev => updateInput(prev, input))
    }

    let isActive = switch state {
    | ShowTokenHint(_)
    | Typing(_) => true
    | HideSuggestion(_) => false
    }

    let deleteButton = switch flags {
    | []
    | [{enabled: false, flag: "a"}] => React.null
    | _ =>
      let onClick = _evt => {
        onUpdate([{WarningFlagDescription.Parser.enabled: false, flag: "a"}])
      }

      <button
        title="Clear all flags"
        onClick
        onFocus
        tabIndex=0
        className="focus:outline-hidden self-start focus:ring-3 hover:cursor-pointer hover:bg-gray-40 p-2 rounded-full"
      >
        <Icon.Close />
      </button>
    }

    let activeClass = if isActive {
      "border-white"
    } else {
      "border-gray-60"
    }

    let areaOnFocus = _evt =>
      if !isActive {
        focusInput()
      }

    let inputValue = switch state {
    | ShowTokenHint({lastState: Typing({input})})
    | Typing({input}) => input
    | HideSuggestion({input}) => input
    | ShowTokenHint(_) => ""
    }

    <div tabIndex={-1} className="relative" onFocus=areaOnFocus onKeyDown>
      <div className={"flex justify-between border p-2 " ++ activeClass}>
        <div>
          chips
          <section className="mt-3">
            <input
              ref={ReactDOM.Ref.domRef((Obj.magic(inputRef): React.ref<Nullable.t<Dom.element>>))}
              className="inline-block p-1 max-w-20 outline-hidden bg-gray-90 placeholder-gray-20/50"
              placeholder="Flags"
              type_="text"
              tabIndex=0
              value=inputValue
              onChange
              onFocus
              onBlur
            />
            <p className="mt-1 text-12">
              {React.string("Type + / - followed by a number or letter (e.g. +a+1)")}
            </p>
          </section>
        </div>
        deleteButton
      </div>
      suggestionBox
    </div>
  }
}

module Settings = {
  @react.component
  let make = (
    ~readyState: CompilerManagerHook.ready,
    ~dispatch: CompilerManagerHook.action => unit,
    ~setConfig: Api.Config.t => unit,
    ~editorCode: React.ref<string>,
    ~config: Api.Config.t,
    ~keyMapState: (CodeMirror.KeyMap.t, (CodeMirror.KeyMap.t => CodeMirror.KeyMap.t) => unit),
  ) => {
    let {Api.Config.warnFlags: warnFlags} = config
    let (keyMap, setKeyMap) = keyMapState

    let availableTargetLangs = Api.Version.availableLanguages(readyState.selected.apiVersion)

    let onTargetLangSelect = lang => dispatch(SwitchLanguage({lang, code: editorCode.current}))

    let onWarningFlagsUpdate = flags => {
      let normalizeEmptyFlags = flags =>
        switch flags {
        | [] => [{WarningFlagDescription.Parser.enabled: false, flag: "a"}]
        | other => other
        }
      let config = {
        ...config,
        warnFlags: flags->normalizeEmptyFlags->WarningFlagDescription.Parser.tokensToString,
      }
      setConfig(config)
    }

    let onModuleSystemUpdate = moduleSystem => {
      let config = {...config, moduleSystem}
      setConfig(config)
    }

    let onJsxPreserveModeUpdate = compilation => {
      let jsxPreserveMode = JsxCompilation.toBool(compilation)
      let config = {...config, jsxPreserveMode}
      setConfig(config)
    }

    let onExperimentalFeaturesUpdate = feature => {
      let features = config.experimentalFeatures->Option.getOr([])

      let experimentalFeatures = if features->Array.includes(feature) {
        features->Array.filter(x => x !== feature)
      } else {
        [...features, feature]
      }

      let config = {...config, experimentalFeatures}
      setConfig(config)
    }

    let warnFlagTokens = WarningFlagDescription.Parser.parse(warnFlags)->Result.getOr([])

    let onWarningFlagsResetClick = _evt => {
      setConfig({
        ...config,
        warnFlags: "+a-4-9-20-40-41-42-50-61-102-109",
      })
    }

    let onCompilerSelect = id => dispatch(SwitchToCompiler(id))

    let titleClass = "hl-5 text-gray-20 mb-2"
    <div className="p-4 pt-8 text-gray-20">
      <div>
        <div className=titleClass> {React.string("ReScript Version")} </div>
        <DropdownSelect
          name="compilerVersions"
          value={Semver.toString(readyState.selected.id)}
          onChange={evt => {
            ReactEvent.Form.preventDefault(evt)
            let id: string = (evt->ReactEvent.Form.target)["value"]
            switch id->Semver.parse {
            | Some(v) =>
              onCompilerSelect(v)
              WebAPI.Storage.setItem(localStorage, ~key=(Url.Playground :> string), ~value=id)
            | None => ()
            }
          }}
        >
          {
            let (experimentalVersions, stableVersions) = readyState.versions->Array.reduce(
              ([], []),
              (acc, item) => {
                let (lhs, rhs) = acc
                if item.preRelease->Option.isSome {
                  Array.push(lhs, item)
                } else {
                  Array.push(rhs, item)
                }->ignore
                acc
              },
            )

            <>
              {switch experimentalVersions {
              | [] => React.null
              | experimentalVersions =>
                let versionByOrder = experimentalVersions->Array.toSorted((b, a) => {
                  if a.major != b.major {
                    a.major - b.major
                  } else if a.minor != b.minor {
                    a.minor - b.minor
                  } else if a.patch != b.patch {
                    a.patch - b.patch
                  } else {
                    switch (a.preRelease, b.preRelease)->Option.all2 {
                    | Some((prereleaseA, prereleaseB)) =>
                      switch (prereleaseA, prereleaseB) {
                      | (Rc(rcA), Rc(rcB)) => rcA - rcB
                      | (Rc(rcA), _) => rcA
                      | (Beta(betaA), Beta(betaB)) => betaA - betaB
                      | (Beta(betaA), _) => betaA
                      | (Alpha(alphaA), Alpha(alphaB)) => alphaA - alphaB
                      | (Alpha(alphaA), _) => alphaA
                      | (Dev(devA), Dev(devB)) => devA - devB
                      | (Dev(devA), _) => devA
                      }

                    | None => 0
                    }
                  }->Float.fromInt
                })
                <>
                  <VersionSelect.SectionHeader value=Constants.dropdownLabelNext />
                  {versionByOrder
                  ->Array.map(version => {
                    let version = Semver.toString(version)
                    <option className="py-4" key=version value=version>
                      {React.string(version)}
                    </option>
                  })
                  ->React.array}
                  <VersionSelect.SectionHeader value=Constants.dropdownLabelReleased />
                </>
              }}
              {switch stableVersions {
              | [] => React.null
              | stableVersions =>
                Array.map(stableVersions, version => {
                  let version = Semver.toString(version)
                  <option className="py-4" key=version value=version>
                    {React.string(version)}
                  </option>
                })->React.array
              }}
            </>
          }
        </DropdownSelect>
      </div>
      {if availableTargetLangs->Array.length > 1 {
        <div className="mt-6">
          <div className=titleClass> {React.string("Syntax")} </div>
          <ToggleSelection
            values=availableTargetLangs
            toLabel={lang => lang->Api.Lang.toExt->String.toUpperCase}
            selected=readyState.targetLang
            onChange=onTargetLangSelect
          />
        </div>
      } else {
        React.null
      }}
      <div className="mt-6">
        <div className=titleClass> {React.string("Use Vim Keymap")} </div>
        <ToggleSelection
          values=[CodeMirror.KeyMap.Default, CodeMirror.KeyMap.Vim]
          toLabel={enabled =>
            switch enabled {
            | CodeMirror.KeyMap.Vim => "On"
            | CodeMirror.KeyMap.Default => "Off"
            }}
          selected=keyMap
          onChange={value => setKeyMap(_ => value)}
        />
      </div>
      <div className="mt-6">
        <div className=titleClass> {React.string("Module-System")} </div>
        <ToggleSelection
          values=["commonjs", "esmodule"]
          toLabel={value => value}
          selected=config.moduleSystem
          onChange=onModuleSystemUpdate
        />
      </div>
      {readyState.selected.apiVersion->RescriptCompilerApi.Version.isMinimumVersion(V6)
        ? <>
            <div className="mt-6">
              <div className=titleClass> {React.string("JSX")} </div>
              <ToggleSelection
                values=[JsxCompilation.Plain, PreserveJsx]
                toLabel=JsxCompilation.getLabel
                selected={config.jsxPreserveMode->Option.getOr(false)->JsxCompilation.fromBool}
                onChange=onJsxPreserveModeUpdate
              />
            </div>
            <div className="mt-6">
              <div className=titleClass> {React.string("Experimental Features")} </div>
              {ExperimentalFeatures.list
              ->Array.map(feature => {
                let key = (feature :> string)

                <SelectionOption
                  key
                  disabled=false
                  label={feature->ExperimentalFeatures.getLabel}
                  isActive={config.experimentalFeatures
                  ->Option.getOr([])
                  ->Array.includes(key)}
                  onClick={_evt => onExperimentalFeaturesUpdate(key)}
                />
              })
              ->React.array}
            </div>
          </>
        : React.null}

      <div className="mt-6">
        <div className=titleClass> {React.string("Loaded Libraries")} </div>
        <ul>
          {Array.map(readyState.selected.libraries, lib => {
            <li className="ml-2" key=lib> {React.string(lib)} </li>
          })->React.array}
        </ul>
      </div>
      <div className="mt-8">
        <div className=titleClass>
          {React.string("Warning Flags")}
          <button
            onClick=onWarningFlagsResetClick className={"ml-6 text-12 " ++ Text.Link.standalone}
          >
            {React.string("[reset]")}
          </button>
        </div>
        <div className="flex justify-end" />
        <div className="max-w-md">
          <WarningFlagsWidget onUpdate=onWarningFlagsUpdate flags=warnFlagTokens />
        </div>
      </div>
    </div>
  }
}

module ControlPanel = {
  module Button = {
    @react.component
    let make = (~children, ~onClick=?) =>
      <button
        ?onClick
        className="inline-block text-sky hover:cursor-pointer hover:bg-sky hover:text-white-80-tr rounded border active:bg-sky-70 border-sky-70 px-2 py-1 "
      >
        children
      </button>
  }

  module ShareButton = {
    let copyToClipboard: string => bool = %raw(`
    function(str) {
      try {
      const el = document.createElement('textarea');
      el.value = str;
      el.setAttribute('readonly', '');
      el.style.position = 'absolute';
      el.style.left = '-9999px';
      document.body.appendChild(el);
      const selected =
        document.getSelection().rangeCount > 0 ? document.getSelection().getRangeAt(0) : false;
      el.select();
      document.execCommand('copy');
      document.body.removeChild(el);
      if (selected) {
        document.getSelection().removeAllRanges();
        document.getSelection().addRange(selected);
      }
      return true;
      } catch(e) {
        return false;
      }
    }
    `)

    type state =
      | Init
      | CopySuccess

    @react.component
    let make = (~actionIndicatorKey: string) => {
      let (state, setState) = React.useState(() => Init)

      React.useEffect(() => {
        setState(_ => Init)
        None
      }, [actionIndicatorKey])

      let onClick = evt => {
        ReactEvent.Mouse.preventDefault(evt)
        let ret = copyToClipboard(window.location.href)
        if ret {
          setState(_ => CopySuccess)
        }
      }

      let (text, className) = switch state {
      | Init => ("Copy Share Link", " bg-sky body-xs active:bg-sky-70 border-sky-70")
      | CopySuccess => ("Copied to clipboard!", "bg-turtle-dark border-turtle-dark")
      }

      <>
        <button
          onClick
          className={className ++ " w-40 transition-all duration-500 ease-in-out inline-block hover:cursor-pointer hover:text-white-80 text-white rounded border px-2 py-1 "}
        >
          {React.string(text)}
        </button>
      </>
    }
  }

  let commandWithKeyboardShortcut = (commandName, ~key) => {
    let userAgent = window.navigator.userAgent
    if userAgent->String.includes("iPhone") || userAgent->String.includes("Android") {
      commandName
    } else if userAgent->String.includes("Mac") {
      `${commandName} (⌘ + ${key})`
    } else {
      `${commandName} (Ctrl + ${key})`
    }
  }

  @react.component
  let make = (
    ~actionIndicatorKey: string,
    ~state: CompilerManagerHook.state,
    ~dispatch: CompilerManagerHook.action => unit,
    ~editorRef: React.ref<option<CodeMirror.editorInstance>>,
    ~setCurrentTab: (tab => tab) => unit,
  ) => {
    let format = () =>
      editorRef.current->Option.forEach(editorInstance =>
        dispatch(Format(CodeMirror.editorGetValue(editorInstance)))
      )
    React.useEffect(() => {
      switch state {
      | Ready(_)
      | Compiling(_)
      | Executing(_) =>
        let onKeyDown = event => {
          switch (
            event->ReactEvent.Keyboard.metaKey || event->ReactEvent.Keyboard.ctrlKey,
            event->ReactEvent.Keyboard.key,
          ) {
          | (true, "e") =>
            event->ReactEvent.Keyboard.preventDefault
            setCurrentTab(_ => Output)
            dispatch(RunCode)
          | (true, "s") =>
            event->ReactEvent.Keyboard.preventDefault
            format()
          | _ => ()
          }
        }

        WebAPI.Window.addEventListener(window, Keydown, onKeyDown)
        Some(() => WebAPI.Window.removeEventListener(window, Keydown, onKeyDown))
      | _ => None
      }
    }, (state, dispatch, setCurrentTab))

    let children = switch state {
    | Init => React.string("Initializing...")
    | SwitchingCompiler(_ready, _version) => React.string("Switching Compiler...")
    | Compiling(_)
    | Executing(_)
    | Ready(_) =>
      let onFormatClick = evt => {
        ReactEvent.Mouse.preventDefault(evt)
        format()
      }

      let autoRun = switch state {
      | CompilerManagerHook.Executing({state: {autoRun: true}})
      | Compiling({state: {autoRun: true}})
      | Ready({autoRun: true}) => true
      | _ => false
      }

      <div className="flex flex-row gap-x-2" dataTestId="control-panel">
        <ToggleButton
          checked=autoRun
          onChange={_ => {
            switch state {
            | Ready({autoRun: false}) => setCurrentTab(_ => Output)
            | _ => ()
            }
            dispatch(ToggleAutoRun)
          }}
        >
          {React.string("Auto-run")}
        </ToggleButton>
        <Button
          onClick={_ => {
            setCurrentTab(_ => Output)
            dispatch(RunCode)
          }}
        >
          {React.string(commandWithKeyboardShortcut("Run", ~key="E"))}
        </Button>
        <Button onClick=onFormatClick>
          {React.string(commandWithKeyboardShortcut("Format", ~key="S"))}
        </Button>
        <ShareButton actionIndicatorKey />
      </div>
    | _ => React.null
    }

    <div className="flex justify-start items-center bg-gray-100 py-3 px-11"> children </div>
  }
}

let locMsgToCmError = (~kind: CodeMirror.Error.kind, locMsg: Api.LocMsg.t): CodeMirror.Error.t => {
  let {Api.LocMsg.row: row, column, endColumn, endRow, shortMsg} = locMsg
  {
    CodeMirror.Error.row,
    column,
    endColumn,
    endRow,
    text: shortMsg,
    kind,
  }
}

module OutputPanel = {
  @react.component
  let make = (
    ~compilerDispatch,
    ~compilerState: CompilerManagerHook.state,
    ~editorCode: React.ref<string>,
    ~keyMapState: (CodeMirror.KeyMap.t, (CodeMirror.KeyMap.t => CodeMirror.KeyMap.t) => unit),
    ~currentTab: tab,
  ) => {
    let output =
      <div className="text-gray-20">
        {switch compilerState {
        | Compiling({previousJsCode: Some(jsCode)})
        | Executing({jsCode})
        | Ready({result: Comp(Success({jsCode}))}) =>
          <pre className={"whitespace-pre-wrap p-4 "}>
            {HighlightJs.renderHLJS(~code=jsCode, ~darkmode=true, ~lang="js", ())}
          </pre>
        | Ready({result: Conv(Success(_))}) => React.null
        | Ready({result, targetLang, selected}) =>
          <ResultPane targetLang compilerVersion=selected.compilerVersion result />
        | _ => React.null
        }}
      </div>

    let errorPane = switch compilerState {
    | Compiling({state: ready})
    | Ready(ready)
    | Executing({state: ready})
    | SwitchingCompiler(ready, _) =>
      <ResultPane
        targetLang=ready.targetLang
        compilerVersion=ready.selected.compilerVersion
        result=ready.result
      />
    | SetupFailed(msg) => <div> {React.string("Setup failed: " ++ msg)} </div>
    | Init => <div> {React.string("Initalizing Playground...")} </div>
    }

    let settingsPane = switch compilerState {
    | Ready(ready)
    | Compiling({state: ready})
    | Executing({state: ready})
    | SwitchingCompiler(ready, _) =>
      let config = ready.selected.config
      let setConfig = config => compilerDispatch(UpdateConfig(config))

      <Settings
        readyState=ready dispatch=compilerDispatch editorCode setConfig config keyMapState
      />
    | SetupFailed(msg) => <div> {React.string("Setup failed: " ++ msg)} </div>
    | Init => <div> {React.string("Initalizing Playground...")} </div>
    }

    let prevSelected = React.useRef(0)

    let selected = switch compilerState {
    | Executing(_)
    | Compiling(_) =>
      prevSelected.current
    | Ready(ready) =>
      switch ready.result {
      | Comp(Success(_))
      | Conv(Success(_)) => 0
      | _ => 1
      }
    | _ => 0
    }

    prevSelected.current = selected

    let appendLog = (level, content) => compilerDispatch(AppendLog({level, content}))

    let tabs = [
      (Output, <OutputPanel compilerState appendLog />),
      (JavaScript, output),
      (Problems, errorPane),
      (Settings, settingsPane),
    ]

    let body = Array.mapWithIndex(tabs, ((tab, content), i) => {
      let className = currentTab == tab ? "block h-inherit" : "hidden"

      <div key={Int.toString(i)} className> content </div>
    })

    <> {body->React.array} </>
  }
}

/**
The initial content is somewhat based on the compiler version.
If we are handling a version that's beyond 10.1, we want to make
sure we are using an example that includes a JSX pragma to
inform the user that you are able to switch between jsx 3 / jsx 4
and the different jsx modes (classic and automatic).
*/
module InitialContent = {
  let original = `module Button = {
  @react.component
  let make = (~count) => {
    let times = switch count {
    | 1 => "once"
    | 2 => "twice"
    | n => n->Belt.Int.toString ++ " times"
    }
    let text = \`Click me $\{times\}\`

    <button> {text->React.string} </button>
  }
}
`

  let since_10_1 = `module CounterMessage = {
  @react.component
  let make = (~count, ~username=?) => {
    let times = switch count {
    | 1 => "once"
    | 2 => "twice"
    | n => Belt.Int.toString(n) ++ " times"
    }

    let name = switch username {
    | Some("") => "Anonymous"
    | Some(name) => name
    | None => "Anonymous"
    }

    <div> {React.string(\`Hello \$\{name\}, you clicked me \` ++ times)} </div>
  }
}

module App = {
  @react.component
  let make = () => {
    let (count, setCount) = React.useState(() => 0)
    let (username, setUsername) = React.useState(() => "Anonymous")

    <div>
      {React.string("Username: ")}
      <input
        type_="text"
        value={username}
        onChange={event => {
          event->ReactEvent.Form.preventDefault
          let eventTarget = event->ReactEvent.Form.target
          let username = eventTarget["value"]
          setUsername(_prev => username)
        }}
      />
      <button
        onClick={_evt => {
          setCount(prev => prev + 1)
        }}>
        {React.string("Click me")}
      </button>
      <button onClick={_evt => setCount(_ => 0)}> {React.string("Reset")} </button>
      <CounterMessage count username />
    </div>
  }
}
`

  let since_11 = `module CounterMessage = {
  @react.component
  let make = (~count, ~username=?) => {
    let times = switch count {
    | 1 => "once"
    | 2 => "twice"
    | n => Int.toString(n) ++ " times"
    }

    let name = switch username {
    | Some("") => "Anonymous"
    | Some(name) => name
    | None => "Anonymous"
    }

    <div> {React.string(\`Hello \$\{name\}, you clicked me \` ++ times)} </div>
  }
}

module App = {
  @react.component
  let make = () => {
    let (count, setCount) = React.useState(() => 0)
    let (username, setUsername) = React.useState(() => "Anonymous")

    <div>
      {React.string("Username: ")}
      <input
        type_="text"
        value={username}
        onChange={event => {
          event->ReactEvent.Form.preventDefault
          let eventTarget = event->ReactEvent.Form.target
          let username = eventTarget["value"]
          setUsername(_prev => username)
        }}
      />
      <button
        onClick={_evt => {
          setCount(prev => prev + 1)
        }}>
        {React.string("Click me")}
      </button>
      <button onClick={_evt => setCount(_ => 0)}> {React.string("Reset")} </button>
      <CounterMessage count username />
    </div>
  }
}
`
}

// Please note:
// ---
// The Playground is still a work in progress
// ReScript / old Reason syntax should parse just
// fine (go to the "Settings" panel for toggling syntax).

// Feel free to play around and compile some
// ReScript code!

let initialReContent = `Js.log("Hello Reason 3.6!");`

@react.component
let make = (~bundleBaseUrl: string, ~versions: array<string>) => {
  let (searchParams, _) = ReactRouter.useSearchParams()
  let containerRef = React.useRef(Nullable.null)
  let editorRef: React.ref<option<CodeMirror.editorInstance>> = React.useRef(None)
  let (_, setScrollLock) = ScrollLockContext.useScrollLock()

  React.useEffect(() => {
    setScrollLock(_ => true)
    None
  }, [])

  let versions =
    versions
    ->Array.filterMap(v => v->Semver.parse)
    ->Array.filter(v =>
      switch v.major {
      | 8 | 9 => false
      | 10 => v.minor >= 1
      | 11 =>
        v.minor >= 1 && v.preRelease->Option.isNone && (v.minor == 1 && v.patch >= 4) ? true : false
      | 12 =>
        switch v.preRelease {
        | None => true
        | Some(_) => v.minor > 1
        }
      | _ => true
      }
    )
    ->Array.toSorted((a, b) => {
      let cmp = ({Semver.major: major, minor, patch, _}) => {
        [major, minor, patch]
        ->Array.map(v => v->Int.toString)
        ->Array.join("")
        ->Int.fromString
        ->Option.getOr(0)
      }

      cmp(b) > cmp(a) ? 1.0 : -1.0
    })

  let initialVersion = switch versions {
  | [v] => Some(v) // only single version available. maybe local dev.
  | versions => {
      let lastStableVersion = versions->Array.find(version => version.preRelease->Option.isNone)
      switch Nullable.make(
        searchParams->WebAPI.URLSearchParams.get((CompilerManagerHook.Version :> string)),
      ) {
      | Nullable.Value(version) => version->Semver.parse
      | _ =>
        switch Url.getVersionFromStorage(Playground) {
        | Some(v) => v->Semver.parse
        | None => lastStableVersion
        }
      }
    }
  }

  let initialLang = switch Nullable.make(
    searchParams->WebAPI.URLSearchParams.get((CompilerManagerHook.Ext :> string)),
  ) {
  | Nullable.Value("re") => Api.Lang.Reason
  | _ => Api.Lang.Res
  }

  let initialModuleSystem =
    Nullable.make(searchParams->WebAPI.URLSearchParams.get((Module :> string)))->Nullable.toOption

  let initialJsxPreserveMode = !(
    Nullable.make(
      searchParams->WebAPI.URLSearchParams.get((JsxPreserve :> string)),
    )->Nullable.isNullable
  )

  let initialExperimentalFeatures =
    Nullable.make(
      searchParams->WebAPI.URLSearchParams.get((Experiments :> string)),
    )->Nullable.mapOr([], str => str->String.split(",")->Array.map(String.trim))

  let initialContent = switch (
    Nullable.make(searchParams->WebAPI.URLSearchParams.get((Code :> string))),
    initialLang,
  ) {
  | (Nullable.Value(compressedCode), _) =>
    LzString.lzString.decompressFromEncodedURIComponent(compressedCode)
  | (_, Reason) => initialReContent
  | (_, Res) =>
    switch initialVersion {
    | Some({major: 10, minor}) if minor >= 1 => InitialContent.since_10_1
    | Some({major}) if major > 10 => InitialContent.since_11
    | _ => InitialContent.original
    }
  }

  // We don't count to infinity. This value is only required to trigger
  // rerenders for specific components (ActivityIndicator)
  let (actionCount, setActionCount) = React.useState(_ => 0)
  let onAction = React.useCallback(
    _ => setActionCount(prev => prev > 1000000 ? 0 : prev + 1),
    [setActionCount],
  )
  let (compilerState, compilerDispatch) = useCompilerManager(
    ~bundleBaseUrl,
    ~initialVersion?,
    ~initialModuleSystem?,
    ~initialJsxPreserveMode,
    ~initialExperimentalFeatures,
    ~initialLang,
    ~onAction,
    ~versions,
  )

  let (keyMap, setKeyMap) = React.useState(() => CodeMirror.KeyMap.Default)
  let typingTimer = React.useRef(None)
  let timeoutCompile = React.useRef(_ => ())

  React.useEffect(() => {
    setKeyMap(_ =>
      Dom.Storage2.localStorage
      ->Dom.Storage2.getItem("vimMode")
      ->Option.map(CodeMirror.KeyMap.fromString)
      ->Option.getOr(CodeMirror.KeyMap.Default)
    )
    None
  }, [])

  React.useEffect(() => {
    switch containerRef.current {
    | Value(parent) =>
      let mode = switch compilerState {
      | Ready({targetLang: Reason}) => "reason"
      | Ready({targetLang: Res}) => "rescript"
      | _ => "rescript"
      }
      let config: CodeMirror.editorConfig = {
        parent,
        initialValue: initialContent,
        mode,
        readOnly: false,
        lineNumbers: true,
        lineWrapping: false,
        keyMap: CodeMirror.KeyMap.Default,
        errors: [],
        hoverHints: [],
        onChange: {
          value => {
            switch typingTimer.current {
            | None => ()
            | Some(timer) => clearTimeout(timer)
            }
            let timer = setTimeout(~handler=() => {
              timeoutCompile.current(value)
              typingTimer.current = None
            }, ~timeout=100)
            typingTimer.current = Some(timer)
          }
        },
      }
      let editor = CodeMirror.createEditor(config)
      editorRef.current = Some(editor)
      Some(() => CodeMirror.editorDestroy(editor))
    | Null | Undefined => None
    }
  }, [])

  React.useEffect(() => {
    Dom.Storage2.localStorage->Dom.Storage2.setItem("vimMode", CodeMirror.KeyMap.toString(keyMap))
    editorRef.current->Option.forEach(CodeMirror.editorSetKeyMap(_, keyMap))
    None
  }, [keyMap])

  let editorCode = React.useRef(initialContent)

  /*
     The codemirror state and the compilerState are not dependent on each other,
     so we need to sync a timeoutCompiler function with our compilerState to be
     able to do compilation on code changes.

     The typingTimer is a debounce mechanism to prevent compilation during editing
     and will be manipulated by the codemirror onChange function.
 */
  React.useEffect(() => {
    timeoutCompile.current = code =>
      switch compilerState {
      | Ready({targetLang}) => compilerDispatch(CompileCode(targetLang, code))
      | _ => ()
      }

    switch (compilerState, editorRef.current) {
    | (Ready({result: FinalResult.Nothing, targetLang}), Some(editorInstance)) =>
      try {
        compilerDispatch(CompileCode(targetLang, CodeMirror.editorGetValue(editorInstance)))
      } catch {
      | err => Console.error(err)
      }
    | (
        Ready({result: FinalResult.Conv(Api.ConversionResult.Success({code}))}),
        Some(editorInstance),
      ) =>
      CodeMirror.editorSetValue(editorInstance, code)
    | (
        Ready({
          result: Comp(Fail(
            SyntaxErr(locMsgs)
            | TypecheckErr(locMsgs)
            | OtherErr(locMsgs),
          )),
        }),
        Some(editorInstance),
      ) =>
      CodeMirror.editorSetErrors(
        editorInstance,
        Array.map(locMsgs, locMsgToCmError(~kind=#Error, ...)),
      )
    | (Ready({result: Comp(Fail(WarningErr(warnings)))}), Some(editorInstance)) =>
      CodeMirror.editorSetErrors(
        editorInstance,
        Array.map(warnings, warning => {
          switch warning {
          | Api.Warning.Warn({details})
          | WarnErr({details}) =>
            locMsgToCmError(~kind=#Warning, details)
          }
        }),
      )
    | (Ready({result: Comp(Success({warnings, typeHints}))}), Some(editorInstance)) =>
      CodeMirror.editorSetErrors(
        editorInstance,
        Array.map(warnings, warning => {
          switch warning {
          | Api.Warning.Warn({details})
          | WarnErr({details}) =>
            locMsgToCmError(~kind=#Warning, details)
          }
        }),
      )
      CodeMirror.editorSetHoverHints(
        editorInstance,
        Array.map(typeHints, hint => {
          switch hint {
          | TypeDeclaration({start, end, hint})
          | Binding({start, end, hint})
          | CoreType({start, end, hint})
          | Expression({start, end, hint}) => {
              CodeMirror.HoverHint.start: {
                line: start.line,
                col: start.col,
              },
              end: {
                line: end.line,
                col: end.col,
              },
              hint,
            }
          }
        }),
      )
    | (Ready({result: Conv(Fail({details}))}), Some(editorInstance)) =>
      CodeMirror.editorSetErrors(
        editorInstance,
        Array.map(details, locMsgToCmError(~kind=#Error, ...)),
      )
    | _ => ()
    }
    None
  }, (compilerState, compilerDispatch))

  let (layout, setLayout) = React.useState(() => Row)

  React.useEffect(() => {
    setLayout(_ => window.innerWidth < breakingPoint ? Column : Row)
    None
  }, [])

  let isDragging = React.useRef(false)

  let panelRef = React.useRef(Nullable.null)

  let separatorRef = React.useRef(Nullable.null)
  let leftPanelRef = React.useRef(Nullable.null)
  let rightPanelRef = React.useRef(Nullable.null)
  let subPanelRef = React.useRef(Nullable.null)

  let onResize = () => {
    let newLayout = window.innerWidth < breakingPoint ? Column : Row
    setLayout(_ => newLayout)
    switch panelRef.current->Nullable.toOption {
    | Some(element) =>
      let offsetTop = WebAPI.Element.getBoundingClientRect(element).top
      WebAPI.Element.setAttribute(
        element,
        ~qualifiedName="style",
        ~value=`height: calc(100vh - ${offsetTop->Float.toString}px)`,
      )
    | None => ()
    }

    switch subPanelRef.current->Nullable.toOption {
    | Some(element) =>
      let offsetTop = WebAPI.Element.getBoundingClientRect(element).top
      WebAPI.Element.setAttribute(
        element,
        ~qualifiedName="style",
        ~value=`height: calc(100vh - ${offsetTop->Float.toString}px)`,
      )
    | None => ()
    }
  }

  React.useEffect(() => {
    WebAPI.Window.addEventListener(window, Resize, onResize)
    Some(() => WebAPI.Window.removeEventListener(window, Resize, onResize))
  }, [])

  // To force CodeMirror render scrollbar on first render
  React.useLayoutEffect(() => {
    onResize()
    None
  }, [])

  let onMouseUp = _ => isDragging.current = false
  let onMouseDown = _ => isDragging.current = true
  let onTouchStart = _ => isDragging.current = true

  React.useEffect(() => {
    let onMove = position => {
      if isDragging.current {
        switch (
          panelRef.current->Nullable.toOption,
          leftPanelRef.current->Nullable.toOption,
          rightPanelRef.current->Nullable.toOption,
          subPanelRef.current->Nullable.toOption,
        ) {
        | (Some(panelElement), Some(leftElement), Some(rightElement), Some(subElement)) =>
          let rectPanel = WebAPI.Element.getBoundingClientRect(panelElement)

          // Update OutputPanel height
          let offsetTop = WebAPI.Element.getBoundingClientRect(subElement).top
          WebAPI.Element.setAttribute(
            subElement,
            ~qualifiedName="style",
            ~value=`height: calc(100vh - ${offsetTop->Float.toString}px)`,
          )

          switch layout {
          | Row =>
            let delta = Int.toFloat(position) -. rectPanel.left

            let leftWidth = delta /. rectPanel.width *. 100.0
            let rightWidth = (rectPanel.width -. delta) /. rectPanel.width *. 100.0

            WebAPI.Element.setAttribute(
              leftElement,
              ~qualifiedName="style",
              ~value=`width: ${leftWidth->Float.toString}%`,
            )
            WebAPI.Element.setAttribute(
              rightElement,
              ~qualifiedName="style",
              ~value=`width: ${rightWidth->Float.toString}%`,
            )

          | Column =>
            let delta = Int.toFloat(position) -. rectPanel.top

            let topHeight = delta /. rectPanel.height *. 100.
            let bottomHeight = (rectPanel.height -. delta) /. rectPanel.height *. 100.

            WebAPI.Element.setAttribute(
              leftElement,
              ~qualifiedName="style",
              ~value=`height: ${topHeight->Float.toString}%`,
            )
            WebAPI.Element.setAttribute(
              rightElement,
              ~qualifiedName="style",
              ~value=`height: ${bottomHeight->Float.toString}%`,
            )
          }
        | _ => ()
        }
      }
    }

    let onMouseMove = e => {
      let position = layout == Row ? ReactEvent.Mouse.clientX(e) : ReactEvent.Mouse.clientY(e)
      onMove(position)
    }

    let onTouchMove = e => {
      let touches = e->ReactEvent.Touch.touches
      let firstTouch = touches["0"]
      let position = layout == Row ? firstTouch["clientX"] : firstTouch["clientY"]
      onMove(position)
    }

    WebAPI.Window.addEventListener(window, Mousemove, onMouseMove)
    WebAPI.Window.addEventListener(window, Touchmove, onTouchMove)
    WebAPI.Window.addEventListener(window, Mouseup, onMouseUp)

    Some(
      () => {
        WebAPI.Window.removeEventListener(window, Mousemove, onMouseMove)
        WebAPI.Window.removeEventListener(window, Touchmove, onTouchMove)
        WebAPI.Window.removeEventListener(window, Mouseup, onMouseUp)
      },
    )
  }, [layout])

  let (currentTab, setCurrentTab) = React.useState(_ => JavaScript)

  let disabled = false

  let makeTabClass = active => {
    let activeClass = active ? "text-white border-sky-70! font-medium hover:cursor-default" : ""

    "flex-1 items-center p-4 border-t-4 border-transparent " ++ activeClass
  }

  let tabs = [JavaScript, Output, Problems, Settings]

  let headers = Array.mapWithIndex(tabs, (tab, i) => {
    let title = switch tab {
    | Output => "Output"->React.string

    | JavaScript => "JavaScript"->React.string

    | Problems => {
        let problemCounts: {"warnings": int, "errors": int} = switch compilerState {
        | Compiling({state: ready})
        | Ready(ready)
        | Executing({state: ready})
        | SwitchingCompiler(ready, _) => {
            "warnings": switch ready.result {
            | Comp(Success({warnings})) => warnings->Array.length
            | _ => 0
            },
            "errors": switch ready.result {
            | FinalResult.Comp(Fail(result)) =>
              switch result {
              | SyntaxErr(errors) | TypecheckErr(errors) | OtherErr(errors) => errors->Array.length
              | WarningErr(errors) => errors->Array.length
              | WarningFlagErr(_) => 1
              }
            | Conv(Fail({details})) => details->Array.length
            | Comp(Success(_)) => 0
            | Conv(Success(_)) => 0
            | Comp(UnexpectedError(_))
            | Conv(UnexpectedError(_))
            | Comp(Unknown(_))
            | Conv(Unknown(_)) => 1
            | Nothing => 0
            },
          }

        | SetupFailed(_) | Init => {
            "warnings": 0,
            "errors": 0,
          }
        }

        <div className="inline-flex items-center gap-2">
          {"Problems"->React.string}
          {if problemCounts["errors"] > 0 {
            <span className="inline-block min-w-4 text-fire bg-fire-100 px-0.5">
              {problemCounts["errors"]->React.int}
            </span>
          } else {
            React.null
          }}
          {if problemCounts["warnings"] > 0 {
            <span className="inline-block min-w-4 text-orange bg-orange-15 px-0.5">
              {problemCounts["warnings"]->React.int}
            </span>
          } else {
            React.null
          }}
        </div>
      }

    | Settings => "Settings"->React.string
    }

    let onClick = evt => {
      ReactEvent.Mouse.preventDefault(evt)
      ReactEvent.Mouse.stopPropagation(evt)
      setCurrentTab(_ => tab)
    }
    let active = currentTab === tab
    let className = makeTabClass(active)
    <button key={Int.toString(i)} onClick className disabled> {title} </button>
  })

  <main className={"flex flex-col bg-gray-100 text-gray-40 text-14"}>
    <ControlPanel
      actionIndicatorKey={Int.toString(actionCount)}
      state=compilerState
      dispatch=compilerDispatch
      setCurrentTab
      editorRef
    />
    <div
      className={`flex ${layout == Column ? "flex-col" : "flex-row"}`}
      ref={ReactDOM.Ref.domRef((Obj.magic(panelRef): React.ref<Nullable.t<Dom.element>>))}
    >
      // Left Panel
      <div
        ref={ReactDOM.Ref.domRef((Obj.magic(leftPanelRef): React.ref<Nullable.t<Dom.element>>))}
        className={`overflow-scroll playground-scrollbar ${layout == Column
            ? "h-2/4"
            : "h-full!"} ${layout == Column ? "w-full" : "w-[50%]"}`}
      >
        <div
          className="bg-gray-100 h-full"
          ref={ReactDOM.Ref.domRef((Obj.magic(containerRef): React.ref<Nullable.t<Dom.element>>))}
        />
      </div>
      // Separator
      <div
        ref={ReactDOM.Ref.domRef((Obj.magic(separatorRef): React.ref<Nullable.t<Dom.element>>))}
        // TODO: touch-none not applied
        className={`flex items-center justify-center touch-none select-none bg-gray-70 opacity-30 hover:opacity-50 rounded-lg ${layout ==
            Column
            ? "cursor-row-resize"
            : "cursor-col-resize"}`}
        onMouseDown={onMouseDown}
        onTouchStart={onTouchStart}
        onTouchEnd={onMouseUp}
      >
        <span className={`m-0.5 ${layout == Column ? "rotate-90" : ""}`}>
          {React.string("⣿")}
        </span>
      </div>
      // Right Panel
      <div
        ref={ReactDOM.Ref.domRef((Obj.magic(rightPanelRef): React.ref<Nullable.t<Dom.element>>))}
        className={`${layout == Column ? "h-6/15" : "h-inherit!"} ${layout == Column
            ? "w-full"
            : "w-[50%]"}`}
      >
        <div className={"flex flex-wrap justify-between w-full " ++ (disabled ? "opacity-50" : "")}>
          {React.array(headers)}
        </div>
        <div
          ref={ReactDOM.Ref.domRef((Obj.magic(subPanelRef): React.ref<Nullable.t<Dom.element>>))}
          className="overflow-auto playground-scrollbar"
        >
          <OutputPanel
            currentTab compilerDispatch compilerState editorCode keyMapState={(keyMap, setKeyMap)}
          />
        </div>
      </div>
    </div>
  </main>
}
