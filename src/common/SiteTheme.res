let storageKey = "siteTheme"
let darkClassName = "site-dark"
let lightClassName = "site-light"

type t = Light | Dark

let toString = (theme: t): string =>
  switch theme {
  | Light => "light"
  | Dark => "dark"
  }

let fromString = (value: string): t =>
  switch value {
  | "dark" => Dark
  | _ => Light
  }

let toggle = (theme: t): t =>
  switch theme {
  | Light => Dark
  | Dark => Light
  }

let applyToDom = (theme: t): unit => {
  let classList = document.documentElement.classList
  switch theme {
  | Dark =>
    WebAPI.DOMTokenList.add(classList, darkClassName)
    WebAPI.DOMTokenList.remove(classList, lightClassName)
  | Light =>
    WebAPI.DOMTokenList.add(classList, lightClassName)
    WebAPI.DOMTokenList.remove(classList, darkClassName)
  }
}

let getPreferred = (): t => {
  let mediaQuery = window->WebAPI.Window.matchMedia("(prefers-color-scheme: dark)")
  mediaQuery.matches ? Dark : Light
}

let getInitial = (): t => {
  let stored = WebAPI.Storage.getItem(window.localStorage, storageKey)->Null.toOption
  switch stored {
  | Some(value) => fromString(value)
  | None => getPreferred()
  }
}

let persist = (theme: t): unit =>
  WebAPI.Storage.setItem(window.localStorage, ~key=storageKey, ~value=theme->toString)

let set = (theme: t): unit => {
  applyToDom(theme)
  persist(theme)
}
