/*
    TODO / Idea list:
    - Fix issue with Reason where a comment on the last line causes a infinite loop
    - Add settings pane to set moduleSystem
    - Add advanced mode for enabling OCaml output as well

    More advanced tasks:
    - Fix syntax convertion issue where comments are stripped on Reason <-> Res convertion
    - Try to get Reason's recoverable errors working
 */

%%raw(`
if (typeof window !== "undefined" && typeof window.navigator !== "undefined") {
  require("codemirror/mode/javascript/javascript");
  require("codemirror/addon/scroll/simplescrollbars");
  require("plugins/cm-rescript-mode");
  require("plugins/cm-reason-mode");
}
`)

open CompilerManagerHook
module Api = RescriptCompilerApi

type layout = Column | Row
type tab = JavaScript | Output | Problems | Settings
let breakingPoint = 1024

module DropdownSelect = {
  @react.component
  let make = (~onChange, ~name, ~value, ~disabled=false, ~children) => {
    let opacity = disabled ? " opacity-50" : ""
    <select
      className={"text-14 bg-transparent border border-gray-80 inline-block rounded px-4 py-1 font-semibold" ++
      opacity}
      name
      value
      disabled
      onChange>
      children
    </select>
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

    let selectedIndex = switch Belt.Array.getIndexBy(values, lang => lang === selected) {
    | Some(i) => i
    | None => 0
    }

    let elements = Array.mapWithIndex(values, (value, i) => {
      let active = i === selectedIndex ? "bg-fire text-white font-bold" : "bg-gray-80 opacity-50"
      let label = toLabel(value)

      let onMouseDown = evt => {
        ReactEvent.Mouse.preventDefault(evt)
        ReactEvent.Mouse.stopPropagation(evt)

        if i !== selectedIndex {
          switch values[i] {
          | Some(value) => onChange(value)
          | None => ()
          }
        }
      }

      // Required for iOS Safari 12
      let onClick = _ => ()

      <button
        disabled
        onMouseDown
        onClick
        key=label
        className={"mr-1 px-2 py-1 rounded inline-block  " ++ active}>
        {React.string(label)}
      </button>
    })

    <div className={(disabled ? "opacity-25" : "") ++ "flex w-full"}> {React.array(elements)} </div>
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
    <div className="pt-4 bg-0 overflow-y-auto">
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
  @set external _scrollTop: (Dom.element, int) => unit = "scrollTop"
  @send external focus: Dom.element => unit = "focus"

  @send external blur: Dom.element => unit = "blur"

  @get external scrollHeight: Dom.element => int = "scrollHeight"
  @get external clientHeight: Dom.element => int = "clientHeight"
  @get external scrollTop: Dom.element => int = "scrollTop"
  @get external offsetTop: Dom.element => int = "offsetTop"
  @get external offsetHeight: Dom.element => int = "offsetHeight"

  @set external setScrollTop: (Dom.element, int) => unit = "scrollTop"

  // Inspired by MUI (who got inspired by WAI best practise examples)
  // https://github.com/mui-org/material-ui/blob/next/packages/material-ui-lab/src/useAutocomplete/useAutocomplete.js#L327
  let scrollToElement = (~parent: Dom.element, element: Dom.element): unit =>
    if parent->scrollHeight > parent->clientHeight {
      let scrollBottom = parent->clientHeight + parent->scrollTop
      let elementBottom = element->offsetTop + element->offsetHeight

      if elementBottom > scrollBottom {
        parent->setScrollTop(elementBottom - parent->clientHeight)
      } else if element->offsetTop - element->offsetHeight < parent->scrollTop {
        parent->setScrollTop(element->offsetTop - element->offsetHeight)
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

    let focusInput = () => inputRef.current->Nullable.forEach(el => el->focus)

    let blurInput = () => inputRef.current->Nullable.forEach(el => el->blur)

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
        key={Int.toString(i) ++ flag}>
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
    | Typing(typing) =>
      let suggestions = switch typing.suggestion {
      | NoSuggestion => React.string("Type + / - followed by a number or letter (e.g. +a+1)")
      | ErrorSuggestion(msg) => React.string(msg)
      | FuzzySuggestions({precedingTokens, selected, results, modifier}) =>
        Array.mapWithIndex(results, ((flag, desc), i) => {
          let activeClass = selected === i ? "bg-gray-40" : ""

          let ref = if selected === i {
            ReactDOM.Ref.callbackDomRef(dom => {
              let el = Nullable.toOption(dom)
              let parent = listboxRef.current->Nullable.toOption

              switch (parent, el) {
              | (Some(parent), Some(el)) => scrollToElement(~parent, el)
              | _ => ()
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
    | HideSuggestion(_) => None
    }

    let suggestionBox =
      Option.map(suggestions, elements =>
        <div
          ref={ReactDOM.Ref.domRef(listboxRef)}
          className="p-2 absolute overflow-auto z-50 border-b rounded border-l border-r block w-full bg-gray-100"
          style={ReactDOM.Style.make(~maxHeight="15rem", ())}>
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
      let onMouseDown = evt => {
        ReactEvent.Mouse.preventDefault(evt)
        onUpdate([{WarningFlagDescription.Parser.enabled: false, flag: "a"}])
      }

      // For iOS12 compat
      let onClick = _ => ()
      let onFocus = evt => {
        ReactEvent.Focus.preventDefault(evt)
        ReactEvent.Focus.stopPropagation(evt)
      }

      <button
        onMouseDown
        onClick
        onFocus
        tabIndex=0
        className="focus:outline-none self-start focus:ring hover:cursor-pointer hover:bg-gray-40 p-2 rounded-full">
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
          <input
            ref={ReactDOM.Ref.domRef(inputRef)}
            className="outline-none bg-gray-90 placeholder-gray-20 placeholder-opacity-50"
            placeholder="Flags"
            type_="text"
            tabIndex=0
            value=inputValue
            onChange
            onFocus
            onBlur
          />
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
  ) => {
    let {Api.Config.warn_flags: warn_flags} = config

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
        warn_flags: flags->normalizeEmptyFlags->WarningFlagDescription.Parser.tokensToString,
      }
      setConfig(config)
    }

    let onModuleSystemUpdate = module_system => {
      let config = {...config, module_system}
      setConfig(config)
    }

    let warnFlagTokens = WarningFlagDescription.Parser.parse(warn_flags)->Result.getOr([])

    let onResetClick = evt => {
      ReactEvent.Mouse.preventDefault(evt)

      let open_modules = switch readyState.selected.apiVersion {
      | V1 | V2 | V3 | UnknownVersion(_) => None
      | V4 | V5 =>
        readyState.selected.libraries->Array.some(el => el === "@rescript/core")
          ? Some(["RescriptCore"])
          : None
      }

      let defaultConfig = {
        Api.Config.module_system: "nodejs",
        warn_flags: "+a-4-9-20-40-41-42-50-61-102-109",
        ?open_modules,
      }
      setConfig(defaultConfig)
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
            | Some(v) => onCompilerSelect(v)
            | None => ()
            }
          }}>
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
                let versionByOrder = experimentalVersions->Belt.SortArray.stableSortBy((a, b) => {
                  let cmp = ({Semver.major: major, minor, patch, preRelease}) => {
                    let preRelease = switch preRelease {
                    | Some(preRelease) =>
                      switch preRelease {
                      | Dev(id) => 0 + id
                      | Alpha(id) => 10 + id
                      | Beta(id) => 20 + id
                      | Rc(id) => 30 + id
                      }
                    | None => 0
                    }
                    let number =
                      [major, minor, patch]
                      ->Array.map(v => v->Int.toString)
                      ->Array.join("")
                      ->Int.fromString
                      ->Option.getOr(0)

                    number + preRelease
                  }
                  cmp(b) - cmp(a)
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
      <div className="mt-6">
        <div className=titleClass> {React.string("Syntax")} </div>
        <ToggleSelection
          values=availableTargetLangs
          toLabel={lang => lang->Api.Lang.toExt->String.toUpperCase}
          selected=readyState.targetLang
          onChange=onTargetLangSelect
        />
      </div>
      <div className="mt-6">
        <div className=titleClass> {React.string("Module-System")} </div>
        <ToggleSelection
          values=["commonjs", "esmodule"]
          toLabel={value => value}
          selected=config.module_system
          onChange=onModuleSystemUpdate
        />
      </div>
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
          <button onMouseDown=onResetClick className={"ml-6 text-12 " ++ Text.Link.standalone}>
            {React.string("[reset]")}
          </button>
        </div>
        <div className="flex justify-end" />
        <div style={ReactDOM.Style.make(~maxWidth="40rem", ())}>
          <WarningFlagsWidget onUpdate=onWarningFlagsUpdate flags=warnFlagTokens />
        </div>
      </div>
    </div>
  }
}

module ControlPanel = {
  let codeFromResult = (result: FinalResult.t): string => {
    open Api
    switch result {
    | FinalResult.Comp(comp) =>
      switch comp {
      | CompilationResult.Success({js_code}) => js_code
      | UnexpectedError(_)
      | Unknown(_, _)
      | Fail(_) => "/* No JS code generated */"
      }
    | Nothing
    | Conv(_) => "/* No JS code generated */"
    }
  }
  module Button = {
    @react.component
    let make = (~children, ~onClick=?) =>
      <button
        ?onClick
        className="inline-block text-sky hover:cursor-pointer hover:bg-sky hover:text-white-80-tr rounded border active:bg-sky-70 border-sky-70 px-2 py-1 ">
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
        let ret = copyToClipboard(Webapi.Window.Location.href)
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
          className={className ++ " w-40 transition-all duration-500 ease-in-out inline-block hover:cursor-pointer hover:text-white-80 text-white rounded border px-2 py-1 "}>
          {React.string(text)}
        </button>
      </>
    }
  }

  @react.component
  let make = (
    ~actionIndicatorKey: string,
    ~state: CompilerManagerHook.state,
    ~dispatch: CompilerManagerHook.action => unit,
    ~editorCode: React.ref<string>,
  ) => {
    let children = switch state {
    | Init => React.string("Initializing...")
    | SwitchingCompiler(_ready, _version) => React.string("Switching Compiler...")
    | Compiling(_)
    | Executing(_)
    | Ready(_) =>
      let onFormatClick = evt => {
        ReactEvent.Mouse.preventDefault(evt)
        dispatch(Format(editorCode.current))
      }

      let autoRun = switch state {
      | CompilerManagerHook.Executing({state: {autoRun: true}})
      | Compiling({autoRun: true})
      | Ready({autoRun: true}) => true
      | _ => false
      }

      let onKeyDown = event => {
        switch (
          event->ReactEvent.Keyboard.metaKey || event->ReactEvent.Keyboard.ctrlKey,
          event->ReactEvent.Keyboard.key,
        ) {
        | (true, "e") => dispatch(RunCode)
        | _ => ()
        }
      }

      React.useEffect(() => {
        Webapi.Window.addEventListener("keydown", onKeyDown)
        Some(() => Webapi.Window.removeEventListener("keydown", onKeyDown))
      }, [])

      let runButtonText = {
        let userAgent = Webapi.Window.Navigator.userAgent
        let run = "Run"
        if userAgent->String.includes("iPhone") || userAgent->String.includes("Android") {
          run
        } else if userAgent->String.includes("Mac") {
          `${run} (⌘ + E)`
        } else {
          `${run} (Ctrl + E)`
        }
      }

      <div className="flex flex-row gap-x-2">
        <ToggleButton checked=autoRun onChange={_ => dispatch(ToggleAutoRun)}>
          {React.string("Auto-run")}
        </ToggleButton>
        <Button onClick={_ => dispatch(RunCode)}> {React.string(runButtonText)} </Button>
        <Button onClick=onFormatClick> {React.string("Format")} </Button>
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
    ~currentTab: tab,
  ) => {
    /*
       We need the prevState to understand different
       state transitions, and to be able to keep displaying
       old results until those transitions are done.

       Goal was to reduce the UI flickering during different
       state transitions
 */
    let prevState = React.useRef(None)

    let cmCode = switch prevState.current {
    | Some(prev) =>
      switch (prev, compilerState) {
      | (_, Ready({result: Nothing})) => None
      | (Ready(prevReady), Ready(ready)) =>
        switch (prevReady.result, ready.result) {
        | (_, Comp(Success(_))) => ControlPanel.codeFromResult(ready.result)->Some
        | _ => None
        }
      | (_, Ready({result: Comp(Success(_)) as result})) =>
        ControlPanel.codeFromResult(result)->Some
      | (Ready({result: Comp(Success(_)) as result}), Compiling(_)) =>
        ControlPanel.codeFromResult(result)->Some
      | (_, Executing({jsCode})) => Some(jsCode)
      | _ => None
      }
    | None =>
      switch compilerState {
      | Ready(ready) => ControlPanel.codeFromResult(ready.result)->Some
      | _ => None
      }
    }

    prevState.current = Some(compilerState)

    let resultPane = switch compilerState {
    | Compiling(ready)
    | Ready(ready)
    | Executing({state: ready}) =>
      switch ready.result {
      | Comp(Success(_))
      | Conv(Success(_)) => React.null
      | _ =>
        <ResultPane
          targetLang=ready.targetLang
          compilerVersion=ready.selected.compilerVersion
          result=ready.result
        />
      }

    | _ => React.null
    }

    let (code, showCm) = switch cmCode {
    | None => ("", false)
    | Some(code) => (code, true)
    }

    let codeElement =
      <pre className={"whitespace-pre-wrap p-4 " ++ (showCm ? "block" : "hidden")}>
        {HighlightJs.renderHLJS(~code, ~darkmode=true, ~lang="js", ())}
      </pre>

    let output =
      <div className="text-gray-20">
        resultPane
        codeElement
      </div>

    let errorPane = switch compilerState {
    | Compiling(ready)
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
    | Compiling(ready)
    | Executing({state: ready})
    | SwitchingCompiler(ready, _) =>
      let config = ready.selected.config
      let setConfig = config => compilerDispatch(UpdateConfig(config))

      <Settings readyState=ready dispatch=compilerDispatch editorCode setConfig config />
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

  let since_10_1 = `@@jsxConfig({ version: 4, mode: "automatic" })

module CounterMessage = {
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
        onChange={evt => {
          evt->ReactEvent.Form.preventDefault
          let username = (evt->ReactEvent.Form.target)["value"]
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
let make = (~versions: array<string>) => {
  let router = Next.Router.useRouter()

  let versions =
    versions
    ->Array.filterMap(v => v->Semver.parse)
    ->Belt.SortArray.stableSortBy((a, b) => {
      let cmp = ({Semver.major: major, minor, patch, _}) => {
        [major, minor, patch]
        ->Array.map(v => v->Int.toString)
        ->Array.join("")
        ->Int.fromString
        ->Option.getOr(0)
      }
      cmp(b) - cmp(a)
    })

  let lastStableVersion = versions->Array.find(version => version.preRelease->Option.isNone)

  let initialVersion = switch Dict.get(router.query, "version") {
  | Some(version) => version->Semver.parse
  | None => lastStableVersion
  }

  let initialLang = switch Dict.get(router.query, "ext") {
  | Some("re") => Api.Lang.Reason
  | _ => Api.Lang.Res
  }

  let initialModuleSystem = Dict.get(router.query, "module")

  let initialContent = switch (Dict.get(router.query, "code"), initialLang) {
  | (Some(compressedCode), _) => LzString.decompressToEncodedURIComponent(compressedCode)
  | (None, Reason) => initialReContent
  | (None, Res)
  | (None, _) =>
    switch initialVersion {
    | Some({major: 10, minor}) if minor >= 1 => InitialContent.since_10_1
    | Some({major}) if major > 10 => InitialContent.since_10_1
    | _ => InitialContent.original
    }
  }

  // We don't count to infinity. This value is only required to trigger
  // rerenders for specific components (ActivityIndicator)
  let (actionCount, setActionCount) = React.useState(_ => 0)
  let onAction = _ => setActionCount(prev => prev > 1000000 ? 0 : prev + 1)
  let (compilerState, compilerDispatch) = useCompilerManager(
    ~initialVersion?,
    ~initialModuleSystem?,
    ~initialLang,
    ~onAction,
    ~versions,
    (),
  )

  // The user can focus an error / warning on a specific line & column
  // which is stored in this ref and triggered by hover / click states
  // in the CodeMirror editor
  let (_focusedRowCol, setFocusedRowCol) = React.useState(_ => None)

  let editorCode = React.useRef(initialContent)

  /* In case the compiler did some kind of syntax conversion / reformatting,
   we take any success results and set the editor code to the new formatted code */
  switch compilerState {
  | Ready({result: FinalResult.Nothing} as ready) =>
    compilerDispatch(CompileCode(ready.targetLang, editorCode.current))
  | Ready({result: FinalResult.Conv(Api.ConversionResult.Success({code}))}) =>
    editorCode.current = code
  | _ => ()
  }

  /*
     The codemirror state and the compilerState are not dependent on eachother,
     so we need to sync a timeoutCompiler function with our compilerState to be
     able to do compilation on code changes.

     The typingTimer is a debounce mechanism to prevent compilation during editing
     and will be manipulated by the codemirror onChange function.
 */
  let typingTimer = React.useRef(None)
  let timeoutCompile = React.useRef(() => ())

  React.useEffect(() => {
    timeoutCompile.current = () =>
      switch compilerState {
      | Ready(ready) => compilerDispatch(CompileCode(ready.targetLang, editorCode.current))
      | _ => ()
      }

    None
  }, (compilerState, compilerDispatch))

  let (layout, setLayout) = React.useState(_ =>
    Webapi.Window.innerWidth < breakingPoint ? Column : Row
  )

  let isDragging = React.useRef(false)

  let panelRef = React.useRef(Nullable.null)

  let separatorRef = React.useRef(Nullable.null)
  let leftPanelRef = React.useRef(Nullable.null)
  let rightPanelRef = React.useRef(Nullable.null)
  let subPanelRef = React.useRef(Nullable.null)

  let onResize = () => {
    let newLayout = Webapi.Window.innerWidth < breakingPoint ? Column : Row
    setLayout(_ => newLayout)
    switch panelRef.current->Nullable.toOption {
    | Some(element) =>
      let offsetTop = Webapi.Element.getBoundingClientRect(element)["top"]
      Webapi.Element.Style.height(element, `calc(100vh - ${offsetTop->Float.toString}px)`)
    | None => ()
    }

    switch subPanelRef.current->Nullable.toOption {
    | Some(element) =>
      let offsetTop = Webapi.Element.getBoundingClientRect(element)["top"]
      Webapi.Element.Style.height(element, `calc(100vh - ${offsetTop->Float.toString}px)`)
    | None => ()
    }
  }

  React.useEffect(() => {
    Webapi.Window.addEventListener("resize", onResize)
    Some(() => Webapi.Window.removeEventListener("resize", onResize))
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
          let rectPanel = Webapi.Element.getBoundingClientRect(panelElement)

          // Update OutputPanel height
          let offsetTop = Webapi.Element.getBoundingClientRect(subElement)["top"]
          Webapi.Element.Style.height(subElement, `calc(100vh - ${offsetTop->Float.toString}px)`)

          switch layout {
          | Row =>
            let delta = Int.toFloat(position) -. rectPanel["left"]

            let leftWidth = delta /. rectPanel["width"] *. 100.0
            let rightWidth = (rectPanel["width"] -. delta) /. rectPanel["width"] *. 100.0

            Webapi.Element.Style.width(leftElement, `${leftWidth->Float.toString}%`)
            Webapi.Element.Style.width(rightElement, `${rightWidth->Float.toString}%`)

          | Column =>
            let delta = Int.toFloat(position) -. rectPanel["top"]

            let topHeight = delta /. rectPanel["height"] *. 100.
            let bottomHeight = (rectPanel["height"] -. delta) /. rectPanel["height"] *. 100.

            Webapi.Element.Style.height(leftElement, `${topHeight->Float.toString}%`)
            Webapi.Element.Style.height(rightElement, `${bottomHeight->Float.toString}%`)
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

    Webapi.Window.addEventListener("mousemove", onMouseMove)
    Webapi.Window.addEventListener("touchmove", onTouchMove)
    Webapi.Window.addEventListener("mouseup", onMouseUp)

    Some(
      () => {
        Webapi.Window.removeEventListener("mousemove", onMouseMove)
        Webapi.Window.removeEventListener("touchmove", onTouchMove)
        Webapi.Window.removeEventListener("mouseup", onMouseUp)
      },
    )
  }, [layout])

  let cmErrors = switch compilerState {
  | Ready({result}) =>
    switch result {
    | FinalResult.Comp(Fail(result)) =>
      switch result {
      | SyntaxErr(locMsgs)
      | TypecheckErr(locMsgs)
      | OtherErr(locMsgs) =>
        Array.map(locMsgs, locMsgToCmError(~kind=#Error, ...))
      | WarningErr(warnings) =>
        Array.map(warnings, warning => {
          switch warning {
          | Api.Warning.Warn({details})
          | WarnErr({details}) =>
            locMsgToCmError(~kind=#Warning, details)
          }
        })
      | WarningFlagErr(_) => []
      }
    | Comp(Success({warnings})) =>
      Array.map(warnings, warning => {
        switch warning {
        | Api.Warning.Warn({details})
        | WarnErr({details}) =>
          locMsgToCmError(~kind=#Warning, details)
        }
      })
    | Conv(Fail({details})) => Array.map(details, locMsgToCmError(~kind=#Error, ...))
    | Comp(_)
    | Conv(_)
    | Nothing => []
    }
  | _ => []
  }

  let cmHoverHints = switch compilerState {
  | Ready({result: FinalResult.Comp(Success({type_hints}))}) =>
    Array.map(type_hints, hint => {
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
    })
  | _ => []
  }

  let mode = switch compilerState {
  | Ready({targetLang: Reason}) => "reason"
  | Ready({targetLang: Res}) => "rescript"
  | _ => "rescript"
  }

  let (currentTab, setCurrentTab) = React.useState(_ => JavaScript)

  let disabled = false

  let makeTabClass = active => {
    let activeClass = active ? "text-white !border-sky-70 font-medium hover:cursor-default" : ""

    "flex-1 items-center p-4 border-t-4 border-transparent " ++ activeClass
  }

  let tabs = [JavaScript, Output, Problems, Settings]

  let headers = Array.mapWithIndex(tabs, (tab, i) => {
    let title = switch tab {
    | Output => "Output"
    | JavaScript => "JavaScript"
    | Problems => "Problems"
    | Settings => "Settings"
    }
    let onMouseDown = evt => {
      ReactEvent.Mouse.preventDefault(evt)
      ReactEvent.Mouse.stopPropagation(evt)
      setCurrentTab(_ => tab)
    }
    let active = currentTab === tab
    // For Safari iOS12
    let onClick = _ => ()
    let className = makeTabClass(active)
    <button key={Int.toString(i) ++ ("-" ++ title)} onMouseDown onClick className disabled>
      {React.string(title)}
    </button>
  })

  <main className={"flex flex-col bg-gray-100 overflow-hidden"}>
    <ControlPanel
      actionIndicatorKey={Int.toString(actionCount)}
      state=compilerState
      dispatch=compilerDispatch
      editorCode
    />
    <div
      className={`flex ${layout == Column ? "flex-col" : "flex-row"}`}
      ref={ReactDOM.Ref.domRef(panelRef)}>
      // Left Panel
      <div
        ref={ReactDOM.Ref.domRef(leftPanelRef)}
        style={ReactDOM.Style.make(~width=layout == Column ? "100%" : "50%", ())}
        className={`${layout == Column ? "h-2/4" : "!h-full"}`}>
        <CodeMirror
          className="bg-gray-100 h-full"
          mode
          hoverHints=cmHoverHints
          errors=cmErrors
          value={editorCode.current}
          onChange={value => {
            editorCode.current = value

            switch typingTimer.current {
            | None => ()
            | Some(timer) => clearTimeout(timer)
            }
            let timer = setTimeout(() => {
              timeoutCompile.current()
              typingTimer.current = None
            }, 100)
            typingTimer.current = Some(timer)
          }}
          onMarkerFocus={rowCol => setFocusedRowCol(_prev => Some(rowCol))}
          onMarkerFocusLeave={_ => setFocusedRowCol(_ => None)}
        />
      </div>
      // Separator
      <div
        ref={ReactDOM.Ref.domRef(separatorRef)}
        style={ReactDOM.Style.make(~cursor=layout == Column ? "row-resize" : "col-resize", ())}
        // TODO: touch-none not applied
        className={`flex items-center justify-center touch-none select-none bg-gray-70 opacity-30 hover:opacity-50 rounded-lg`}
        onMouseDown={onMouseDown}
        onTouchStart={onTouchStart}
        onTouchEnd={onMouseUp}>
        <span className={`m-0.5 ${layout == Column ? "rotate-90" : ""}`}>
          {React.string("⣿")}
        </span>
      </div>
      // Right Panel
      <div
        ref={ReactDOM.Ref.domRef(rightPanelRef)}
        style={ReactDOM.Style.make(~width=layout == Column ? "100%" : "50%", ())}
        className={`${layout == Column ? "h-6/15" : "!h-inherit"}`}>
        <div className={"flex flex-wrap justify-between w-full " ++ (disabled ? "opacity-50" : "")}>
          {React.array(headers)}
        </div>
        <div ref={ReactDOM.Ref.domRef(subPanelRef)} className="overflow-auto">
          <OutputPanel currentTab compilerDispatch compilerState editorCode />
        </div>
      </div>
    </div>
  </main>
}
