let langShortname = (lang: string) =>
  switch lang {
  | "ocaml" => "ml"
  | "reasonml"
  | "reason"
  | "rescript" => "res"
  | "bash" => "sh"
  | "text" => ""
  | rest => rest
  }

@react.component
let make = (
  ~highlightedLines=[],
  ~code: string,
  ~showLabel=true,
  ~lang="text",
  ~showCopyButton=false,
) => {
  let children = HighlightJs.renderHLJS(~highlightedLines, ~code, ~lang, ())

  let label = if showLabel {
    let label = langShortname(lang)
    let rightPosition = if showCopyButton {
      "right-8" // Move label left when copy button is present
    } else {
      "right-1"
    }
    let topPosition = if showCopyButton {
      "top-1"
    } else {
      "top-0"
    }
    <div
      className={`absolute ${rightPosition} ${topPosition} p-1 font-sans text-12 font-bold text-gray-30 pointer-events-none`}
    >
      {//RES or JS Label
      String.toUpperCase(label)->React.string}
    </div>
  } else {
    React.null
  }

  let copyButton = if showCopyButton {
    <div className="absolute right-1 top-0 p-1">
      <CodeCopyButton key=code code />
    </div>
  } else {
    React.null
  }

  <div
    //normal code-text without tabs
    className="relative w-full flex-col rounded xs:rounded border border-gray-20 bg-gray-10 pt-2 text-gray-80"
  >
    label
    copyButton
    <div className="px-5 text-14 pt-4 pb-4 overflow-x-auto whitespace-pre"> children </div>
  </div>
}

module Toggle = {
  type tab = {
    highlightedLines: option<array<int>>,
    label: option<string>,
    lang: option<string>,
    code: string,
  }

  @react.component
  let make = (~tabs: array<tab>) => {
    let (selected, setSelected) = React.useState(_ => 0)

    switch tabs {
    | [tab] =>
      make({
        highlightedLines: ?tab.highlightedLines,
        code: tab.code,
        lang: ?tab.lang,
        showLabel: true,
        showCopyButton: true,
      })
    | multiple =>
      let numberOfItems = Array.length(multiple)
      let tabElements = Array.mapWithIndex(multiple, (tab, i) => {
        // if there's no label, infer the label from the language
        let label = switch tab.label {
        | Some(label) => label
        | None =>
          switch tab.lang {
          | Some(lang) => langShortname(lang)->String.toUpperCase
          | None => Int.toString(i)
          }
        }

        let activeClass = if selected === i {
          "font-medium text-12 text-gray-40 bg-gray-5 border-t-2 first:border-l"
        } else {
          "font-medium text-12 hover:text-gray-60 border-t-2 bg-gray-20 hover:cursor-pointer"
        }

        let onClick = evt => {
          ReactEvent.Mouse.preventDefault(evt)
          setSelected(_ => i)
        }
        let key = label ++ ("-" ++ Int.toString(i))

        let paddingX = switch numberOfItems {
        | 1
        | 2 => "sm:px-4"
        | 3 => "lg:px-8"
        | _ => ""
        }

        let borderColor = if selected === i {
          "border-t-gray-60"
        } else {
          "border-t-transparent"
        }

        <span
          key
          className={paddingX ++
          (` ${borderColor} flex-none px-5 inline-block p-1 first:rounded-tl ` ++
          activeClass)}
          onClick
        >
          {React.string(label)}
        </span>
      })

      let children =
        multiple[selected]
        ->Option.map(tab => {
          let lang = Option.getOr(tab.lang, "text")
          HighlightJs.renderHLJS(~highlightedLines=?tab.highlightedLines, ~code=tab.code, ~lang, ())
        })
        ->Option.getOr(React.null)

      // On a ReScript tab, always copy or open the ReScript code. Otherwise, copy the current selected code.
      let isReScript = tab =>
        switch tab.lang {
        | Some("res") | Some("rescript") => true
        | _ => false
        }

      let buttonDiv = switch Array.findWithIndex(multiple, (tab, index) =>
        tab->isReScript || index === selected
      ) {
      | Some({code: ""}) => React.null
      | Some(tab) =>
        open ReactRouter
        let playgroundLinkButton =
          tab->isReScript
            ? <Link.String
                to={`/try?code=${LzString.lzString.compressToEncodedURIComponent(tab.code)}`}
                target="_blank"
              >
                // ICON Link to PLAYGROUND
                <Icon.ExternalLink
                  className="text-gray-30 mt-px hover:cursor-pointer hover:text-gray-60 hover:bg-gray-30 w-6 h-6 p-1 rounded transition-all duration-300 ease-in-out"
                />
              </Link.String>
            : React.null

        let copyButton = <CodeCopyButton key=tab.code code={tab.code} />

        <div className="flex items-center justify-end h-full pr-4 space-x-2">
          playgroundLinkButton
          copyButton
        </div>
      | None => React.null
      }

      <div className="relative pt-6 w-full rounded-none text-gray-80">
        //text within code-box
        <div
          className="absolute flex w-full font-sans bg-transparent text-14 text-gray-40 mt-[-26px] overflow-x-auto"
        >
          <div className="flex xs:ml-0"> {React.array(tabElements)} </div>
          <div className="flex-1 w-full bg-gray-20 border-b rounded-tr border-gray-20 items-center">
            buttonDiv
          </div>
        </div>
        <div
          className="px-4 lg:px-5 text-14 pb-4 pt-4 overflow-x-auto bg-gray-10 border-gray-20 rounded-b border"
        >
          <pre> children </pre>
        </div>
      </div>
    }
  }
}
