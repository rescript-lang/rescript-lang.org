type state =
  | Init
  | Pending
  | CopySuccess
  | CopyFailed

@react.component
let make = (~writeClipboard=Clipboard.writeText) => {
  let (state, setState) = React.useState(() => Init)

  let copy = async () => {
    setState(_ => Pending)
    let result = await writeClipboard(window.location.href)
    setState(_ =>
      switch result {
      | Ok() => CopySuccess
      | Error(_) => CopyFailed
      }
    )
  }
  let onClick = evt => {
    ReactEvent.Mouse.preventDefault(evt)
    copy()->ignore
  }

  let (text, className) = switch state {
  | Init | Pending => ("Copy Share Link", " bg-sky body-xs active:bg-sky-70 border-sky-70")
  | CopySuccess => ("Copied to clipboard!", "bg-turtle-dark border-turtle-dark")
  | CopyFailed => ("Copy failed, try again", " bg-sky body-xs active:bg-sky-70 border-sky-70")
  }

  <>
    <button
      onClick
      type_="button"
      disabled={state === Pending}
      className={className ++ " w-40 transition-all duration-500 ease-in-out inline-block hover:cursor-pointer hover:text-white-80 text-white rounded border px-2 py-1 "}
    >
      {React.string(text)}
    </button>
  </>
}
