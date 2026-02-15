let link = "no-underline block hover:cursor-pointer hover:text-fire-30 mb-px"
let activeLink = "font-medium text-fire-30 border-b border-fire"

let linkOrActiveLink = (~target: Path.t, ~route: Path.t) => target === route ? activeLink : link

let linkOrActiveLinkSubroute = (~target: Path.t, ~route: Path.t) =>
  String.startsWith((route :> string), (target :> string)) ? activeLink : link

external elementToDialog: WebAPI.DOMAPI.element => WebAPI.DOMAPI.htmlDialogElement = "%identity"

let getMobileOverlayDialog = () => {
  Nullable.make(document->WebAPI.Document.getElementById("mobile-overlay")->elementToDialog)
}

@get external _open: WebAPI.DOMAPI.htmlDialogElement => bool = "open"

let openMobileOverlay = _ =>
  switch getMobileOverlayDialog() {
  | Nullable.Value(dialog) => dialog->WebAPI.HTMLDialogElement.showModal
  | Null => ()
  | Undefined => ()
  }

let closeMobileOverlay = _ =>
  switch getMobileOverlayDialog() {
  | Nullable.Value(dialog) => dialog->WebAPI.HTMLDialogElement.close
  | Null => ()
  | Undefined => ()
  }

let toggleMobileOverlay = _ => {
  let isOpen = switch getMobileOverlayDialog() {
  | Nullable.Value(dialog) => dialog->_open
  | Null => false
  | Undefined => false
  }

  if isOpen {
    closeMobileOverlay()
  } else {
    openMobileOverlay()
  }
}
