open Cypress

let headline = "JavaScript Made Simple for Humans and AI"

let grantClipboardPermissions = () => {
  run(() =>
    automate({
      command: "Browser.grantPermissions",
      params: {
        permissions: ["clipboardReadWrite", "clipboardSanitizedWrite"],
        origin: baseUrl(),
      },
    })
  )->ignore
}

let denyClipboardPermissions = () => {
  run(() =>
    automate({
      command: "Browser.grantPermissions",
      params: {permissions: [], origin: baseUrl()},
    })
  )->ignore
}

let readClipboard = () => cyWindow()->thenPromise(window => window.navigator.clipboard->readText)

let homepageDocument = callback => {
  request("/")
  ->then(response => {
    expect(response.status)->equal(200)
    callback(parser()->parseHtml(response.body))
  })
  ->ignore
}

let initialScriptUrls = document =>
  document
  ->querySelectorAll(`link[rel="modulepreload"][href], script[src]`)
  ->elementsFrom
  ->Array.filterMap(element =>
    element
    ->getAttribute("href")
    ->Null.toOption
    ->Option.orElse(element->getAttribute("src")->Null.toOption)
  )

let expectElement = (document, selector) => {
  let element = document->querySelector(selector)->Null.toOption
  expect(element->Option.isSome, ~message=selector)->equal(true)
  element
}
