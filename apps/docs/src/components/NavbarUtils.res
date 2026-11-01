let link = "no-underline block hover:cursor-pointer hover:text-fire-30 mb-px"
let activeLink = "font-medium text-fire-30 border-b border-fire"

let isActiveLink = (~includes: string, ~excludes: option<string>=?, ~route: Path.t) => {
  let route = (route :> string)
  // includes means we want the link to be active if it contains the expected text
  let includes = route->String.includes(includes)
  // excludes allows us to not have links be active even if they do have the includes text
  let excludes = switch excludes {
  | Some(excludes) => route->String.includes(excludes)
  | None => false
  }
  includes && !excludes ? activeLink : link
}

let linkOrActiveLink = (~target: Path.t, ~route: Path.t) => target === route ? activeLink : link

let linkOrActiveLinkSubroute = (~target: Path.t, ~route: Path.t) =>
  String.startsWith(route :> string, target :> string) ? activeLink : link

external elementToDialog: WebAPI.Element.t => WebAPI.HTMLDialogElement.t = "%identity"

let getMobileOverlayDialog = () => {
  WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.getElementById("mobile-overlay")
  ->Null.toOption
  ->Option.map(elementToDialog)
}

@get external _open: WebAPI.HTMLDialogElement.t => bool = "open"

let openMobileOverlay = _ =>
  switch getMobileOverlayDialog() {
  | Some(dialog) => dialog->WebAPI.HTMLDialogElement.showModal
  | None => ()
  }

let closeMobileOverlay = _ =>
  switch getMobileOverlayDialog() {
  | Some(dialog) => dialog->WebAPI.HTMLDialogElement.close
  | None => ()
  }

let toggleMobileOverlay = _ => {
  let isOpen = switch getMobileOverlayDialog() {
  | Some(dialog) => dialog->_open
  | None => false
  }

  if isOpen {
    closeMobileOverlay()
  } else {
    openMobileOverlay()
  }
}

let getMobileTertiaryDialog = () => {
  WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.getElementById("mobile-tertiary-drawer")
  ->Null.toOption
  ->Option.map(elementToDialog)
}

let openMobileTertiaryDrawer = _ =>
  switch getMobileTertiaryDialog() {
  | Some(dialog) => dialog->WebAPI.HTMLDialogElement.showModal
  | None => ()
  }

let closeMobileTertiaryDrawer = _ =>
  switch getMobileTertiaryDialog() {
  | Some(dialog) => dialog->WebAPI.HTMLDialogElement.close
  | None => ()
  }

let toggleMobileTertiaryDrawer = _ => {
  let isOpen = switch getMobileTertiaryDialog() {
  | Some(dialog) => dialog->_open
  | None => false
  }

  if isOpen {
    closeMobileTertiaryDrawer()
  } else {
    openMobileTertiaryDrawer()
  }
}

let isDocRoute = (~route: Path.t) => {
  let route = (route :> string)
  route->String.includes("/docs/") || route->String.includes("/syntax-lookup")
}
