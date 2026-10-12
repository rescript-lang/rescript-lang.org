type error = WriteFailed

let writeText = async text => {
  try {
    await navigator.clipboard->WebAPI.Clipboard.writeText(text)
    Ok()
  } catch {
  | _ => Error(WriteFailed)
  }
}
