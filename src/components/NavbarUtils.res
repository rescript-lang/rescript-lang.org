let link = "no-underline block hover:cursor-pointer hover:text-fire-30 mb-px"
let activeLink = "font-medium text-fire-30 border-b border-fire"

let linkOrActiveLink = (~target: Path.t, ~route: Path.t) => target === route ? activeLink : link

let linkOrActiveLinkSubroute = (~target: Path.t, ~route: Path.t) =>
  String.startsWith((route :> string), (target :> string)) ? activeLink : link

external elementToDialog: WebAPI.DOMAPI.element => WebAPI.DOMAPI.htmlDialogElement = "%identity"

let getMobileOverlayDialog = () => {
  document->WebAPI.Document.getElementById("mobile-overlay")->elementToDialog
}

@get external _open: WebAPI.DOMAPI.htmlDialogElement => bool = "open"

let openMobileOverlay = _ => getMobileOverlayDialog()->WebAPI.HTMLDialogElement.showModal

let closeMobileOverlay = _ => getMobileOverlayDialog()->WebAPI.HTMLDialogElement.close

let toggleMobileOverlay = _ => {
  let isOpen = getMobileOverlayDialog()->_open

  if isOpen {
    closeMobileOverlay()
  } else {
    openMobileOverlay()
  }
}
