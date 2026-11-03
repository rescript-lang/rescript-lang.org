type error = WriteFailed

@send
external createTextArea: (WebAPI.DOM.document, @as("textarea") _) => WebAPI.HTMLTextAreaElement.t =
  "createElement"

@send external copySelection: (WebAPI.DOM.document, @as("copy") _) => bool = "execCommand"
@send external focusElement: WebAPI.Element.t => unit = "focus"

@send
external getSelection: WebAPI.DOM.document => Null.t<WebAPI.Selection.t> = "getSelection"

let writeWithSelection = text => {
  try {
    let textarea = createTextArea(WebAPI.DOM.window->WebAPI.Window.document)
    let activeElement = WebAPI.DOM.window->WebAPI.Window.document->WebDocument.activeElement
    let selection = getSelection(WebAPI.DOM.window->WebAPI.Window.document)->Null.toOption
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
      WebAPI.DOM.window
      ->WebAPI.Window.document
      ->WebDocument.body
      ->WebAPI.HTMLElement.appendChild(textarea->WebAPI.HTMLTextAreaElement.asNode)
      ->ignore
      textarea->WebAPI.HTMLTextAreaElement.select
      copySelection(WebAPI.DOM.window->WebAPI.Window.document)
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
    await WebAPI.DOM.window
    ->WebAPI.Window.navigator
    ->WebAPI.Navigator.clipboard
    ->WebAPI.Clipboard.writeText(text)
    Ok()
  } catch {
  | _ => writeWithSelection(text)
  }
}
