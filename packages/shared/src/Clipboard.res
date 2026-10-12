type error = WriteFailed

@send
external createTextArea: (
  WebAPI.DOMAPI.document,
  @as("textarea") _,
) => WebAPI.DOMAPI.htmlTextAreaElement = "createElement"

@send external copySelection: (WebAPI.DOMAPI.document, @as("copy") _) => bool = "execCommand"
@send external focusElement: WebAPI.DOMAPI.element => unit = "focus"
@send
external getSelection: WebAPI.DOMAPI.document => Null.t<WebAPI.DOMAPI.selection> = "getSelection"

let writeWithSelection = text => {
  try {
    let textarea = createTextArea(document)
    let activeElement = document.activeElement
    let selection = getSelection(document)->Null.toOption
    let ranges =
      selection->Option.mapOr([], selection =>
        Array.fromInitializer(~length=selection.rangeCount, index =>
          selection->WebAPI.Selection.getRangeAt(index)->WebAPI.Range.cloneRange
        )
      )

    let copied = try {
      textarea.value = text
      textarea.readOnly = true
      textarea->WebAPI.HTMLTextAreaElement.setAttribute(
        ~qualifiedName="style",
        ~value="position: fixed; left: -9999px; top: 0",
      )
      document.body
      ->WebAPI.HTMLElement.appendChild(textarea->WebAPI.HTMLTextAreaElement.asNode)
      ->ignore
      textarea->WebAPI.HTMLTextAreaElement.select
      copySelection(document)
    } catch {
    | _ => false
    }

    textarea->WebAPI.HTMLTextAreaElement.remove
    activeElement->Null.forEach(focusElement)
    selection->Option.forEach(selection => {
      selection->WebAPI.Selection.removeAllRanges
      ranges->Array.forEach(range => selection->WebAPI.Selection.addRange(range))
    })

    copied ? Ok() : Error(WriteFailed)
  } catch {
  | _ => Error(WriteFailed)
  }
}

let writeText = async text => {
  try {
    await navigator.clipboard->WebAPI.Clipboard.writeText(text)
    Ok()
  } catch {
  | _ => writeWithSelection(text)
  }
}
