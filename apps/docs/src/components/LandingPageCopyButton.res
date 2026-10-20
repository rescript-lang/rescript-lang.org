type state =
  | Idle
  | Pending
  | Copied
  | Failed

let useFeedbackRef = setState => React.useCallback(_ => {
    let timer = setTimeout(~handler=() => setState(_ => Idle), ~timeout=2000)
    Some(() => clearTimeout(timer))
  }, [])

@react.component
let make =
  @directive("'use memo'")
  (~code, ~writeClipboard=Clipboard.writeText) => {
    let (state, setState) = React.useState(_ => Idle)
    let feedbackRef = useFeedbackRef(setState)

    let copy = async () => {
      setState(_ => Pending)
      let result = await writeClipboard(code)
      setState(_ => {
        switch result {
        | Ok() => Copied
        | Error(Clipboard.WriteFailed) => Failed
        }
      })
    }

    let feedback = switch state {
    | Idle | Pending => React.null
    | Copied =>
      <span
        ref={ReactDOM.Ref.callbackDomRef(feedbackRef)}
        className="absolute top-0 mt-4 -mr-1 px-2 rounded right-0 bg-turtle text-gray-80-tr body-sm"
      >
        {React.string("Copied!")}
      </span>
    | Failed =>
      <span
        className="absolute top-0 mt-4 -mr-1 px-2 rounded right-0 bg-fire-5 text-fire-90 body-sm w-40"
      >
        {React.string("Could not copy. Try again.")}
      </span>
    }

    <>
      <button
        type_="button"
        disabled={state === Pending || state === Copied}
        className="h-10 w-10 flex justify-center items-center"
        onClick={_ => copy()->ignore}
        ariaLabel={"Copy " ++ code ++ " command"}
      >
        <Icon.Copy className="w-6 h-6 mt-px text-gray-40 hover:cursor-pointer hover:text-gray-80" />
      </button>
      <span role="status" className="absolute top-3 right-3 pointer-events-none"> feedback </span>
    </>
  }
