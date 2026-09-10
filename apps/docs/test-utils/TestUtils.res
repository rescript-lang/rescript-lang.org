let getByTextExact = (element, text) => Vitest.getByTextWithOptions(element, text, {"exact": true})

let sleep = ms =>
  Promise.make((resolve, _) => {
    let _timeoutId = setTimeout(~handler=() => {
      resolve()
    }, ~timeout=ms)
  })

external imageFromElement: DomTypes.element => DomTypes.htmlImageElement = "%identity"

let waitForImages = async (selector: string) => {
  let root = switch document->Document.querySelector(selector) {
  | Value(root) => root
  | Null => failwith(`expected to find screenshot target ${selector}`)
  }

  let images = root->Element.querySelectorAll("img")

  if images.length > 0 {
    for i in 0 to images.length - 1 {
      let image = images->NodeList.item(i)->imageFromElement
      await image->HTMLImageElement.decode
    }
  }
}
