@directive("use client")
let langShortname = (lang: string) =>
  switch lang {
  | "ocaml" => "ml"
  | "reasonml"
  | "reason" => "re"
  | "bash" => "sh"
  | "text" => ""
  | rest => rest
  }

module CopyButton = {
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
    | Copied
    | Failed

  @react.component
  let make = (~code) => {
    let (state, setState) = React.useState(_ => Init)

    let buttonRef = React.useRef(Nullable.null)

    let onClick = evt => {
      ReactEvent.Mouse.preventDefault(evt)
      if copyToClipboard(code) {
        setState(_ => Copied)
      } else {
        setState(_ => Failed)
      }
    }

    React.useEffect(() => {
      switch state {
      | Copied =>
        let buttonEl = Nullable.toOption(buttonRef.current)->Option.getOrThrow

        // Note on this imperative DOM nonsense:
        // For Tailwind transitions to behave correctly, we need to first paint the DOM element in the tree,
        // and in the next tick, add the opacity-100 class, so the transition animation actually takes place.
        // If we don't do that, the banner will essentially pop up without any animation
        let bannerEl = WebAPI.Document.createElement(document, "div")
        bannerEl.className = "opacity-0 absolute -top-6 right-0 -mt-5 -mr-4 px-4 py-2 w-40 rounded-lg captions text-white bg-gray-100 text-gray-80-tr transition-all duration-1000 ease-in-out "

        let textNode = WebAPI.Document.createTextNode(document, "Copied to clipboard")

        WebAPI.Element.appendChild(bannerEl, textNode)->ignore
        WebAPI.Element.appendChild(buttonEl, bannerEl)->ignore

        let nextFrameId = WebAPI.Window.requestAnimationFrame(window, _ => {
          WebAPI.DOMTokenList.toggle(bannerEl.classList, ~token="opacity-0")->ignore
          WebAPI.DOMTokenList.toggle(bannerEl.classList, ~token="opacity-100")->ignore
        })

        let timeoutId = setTimeout(~handler=() => {
          buttonEl->WebAPI.Element.removeChild(bannerEl)->ignore
          setState(_ => Init)
        }, ~timeout=3000)

        Some(
          () => {
            cancelAnimationFrame(nextFrameId)
            clearTimeout(timeoutId)
          },
        )
      | _ => None
      }
    }, [state])
    //Copy-Button
    <button
      ref={ReactDOM.Ref.domRef((Obj.magic(buttonRef): React.ref<Nullable.t<Dom.element>>))}
      disabled={state === Copied}
      className="relative"
      onClick>
      <Icon.Clipboard
        className="text-gray-30 mt-px hover:cursor-pointer hover:text-gray-60 hover:bg-gray-30 w-6 h-6 p-1 rounded transition-all duration-300 ease-in-out"
      />
    </button>
  }
}

@react.component
let make = (~highlightedLines=[], ~code: string, ~showLabel=true, ~lang="text") => {
  let children = HighlightJs.renderHLJS(~highlightedLines, ~code, ~lang, ())

  let label = if showLabel {
    let label = langShortname(lang)
    <div
      className="absolute right-1 top-0 p-1 font-sans text-12 font-bold text-gray-30 pointer-events-none">
      {//RES or JS Label
      String.toUpperCase(label)->React.string}
    </div>
  } else {
    React.null
  }

  <div
    //normal code-text without tabs
    className="relative w-full flex-col rounded xs:rounded border border-gray-20 bg-gray-10 pt-2 text-gray-80">
    label
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
          "border-t-[#696b7d]"
        } else {
          "border-t-[transparent]"
        }

        <span
          key
          className={paddingX ++
          (` ${borderColor} flex-none px-5 inline-block p-1 first:rounded-tl ` ++
          activeClass)}
          onClick>
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
        let playgroundLinkButton =
          tab->isReScript
            ? <Next.Link
                href={`/try?code=${LzString.compressToEncodedURIComponent(tab.code)}}`}
                target="_blank">
                // ICON Link to PLAYGROUND
                <Icon.ExternalLink
                  className="text-gray-30 mt-px hover:cursor-pointer hover:text-gray-60 hover:bg-gray-30 w-6 h-6 p-1 rounded transition-all duration-300 ease-in-out"
                />
              </Next.Link>
            : React.null

        let copyButton = <CopyButton code={tab.code} />

        <div className="flex items-center justify-end h-full pr-4 space-x-2">
          playgroundLinkButton
          copyButton
        </div>
      | None => React.null
      }

      <div className="relative pt-6 w-full rounded-none text-gray-80">
        //text within code-box
        <div
          className="absolute flex w-full font-sans bg-transparent text-14 text-gray-40 mt-[-26px] overflow-x-auto">
          <div className="flex xs:ml-0"> {React.array(tabElements)} </div>
          <div className="flex-1 w-full bg-gray-20 border-b rounded-tr border-gray-20 items-center">
            buttonDiv
          </div>
        </div>
        <div
          className="px-4 lg:px-5 text-14 pb-4 pt-4 overflow-x-auto bg-gray-10 border-gray-20 rounded-b border">
          <pre> children </pre>
        </div>
      </div>
    }
  }
}
