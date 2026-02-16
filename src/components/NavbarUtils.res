let link = "no-underline block hover:cursor-pointer hover:text-fire-30 mb-px"
let activeLink = "font-medium text-fire-30 border-b border-fire"

let isActiveLink = (~includes: string, ~excludes: option<string>=?, ~route: Path.t) => {
  let route = (route :> string)
  // includes means we want the lnk to be active if it contains the expected text
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

let getMobileTertiaryDialog = () => {
  Nullable.make(document->WebAPI.Document.getElementById("mobile-tertiary-drawer")->elementToDialog)
}

let openMobileTertiaryDrawer = _ =>
  switch getMobileTertiaryDialog() {
  | Nullable.Value(dialog) => dialog->WebAPI.HTMLDialogElement.show
  | Null => ()
  | Undefined => ()
  }

let closeMobileTertiaryDrawer = _ =>
  switch getMobileTertiaryDialog() {
  | Nullable.Value(dialog) => dialog->WebAPI.HTMLDialogElement.close
  | Null => ()
  | Undefined => ()
  }

let toggleMobileTertiaryDrawer = _ => {
  let isOpen = switch getMobileTertiaryDialog() {
  | Nullable.Value(dialog) => dialog->_open
  | Null => false
  | Undefined => false
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
