let getByTextExact = (element, text) => Vitest.getByTextWithOptions(element, text, {"exact": true})

let sleep = ms =>
  Promise.make((resolve, _) => {
    let _timeoutId = setTimeout(~handler=() => {
      resolve()
    }, ~timeout=ms)
  })

external imageFromNode: WebAPI.DOMAPI.node => WebAPI.DOMAPI.htmlImageElement = "%identity"

let waitForImages = async (selector: string) => {
  let root = switch document->WebAPI.Document.querySelector(selector) {
  | Value(root) => root
  | Null => failwith(`expected to find screenshot target ${selector}`)
  }

  let images = root->WebAPI.Element.querySelectorAll("img")

  if images.length > 0 {
    for i in 0 to images.length - 1 {
      let image = images->WebAPI.NodeList.item(i)->imageFromNode
      await image->WebAPI.HTMLImageElement.decode
    }
  }
}
