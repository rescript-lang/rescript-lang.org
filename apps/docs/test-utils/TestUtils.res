external imageFromElement: WebAPI.Element.t => WebAPI.HTMLImageElement.t = "%identity"

let waitForImages = async (selector: string) => {
  let root = switch WebAPI.DOM.window
  ->WebAPI.Window.document
  ->WebAPI.Document.querySelector(selector) {
  | Value(root) => root
  | Null => panic(`expected to find screenshot target ${selector}`)
  }

  let images = root->WebAPI.Element.querySelectorAll("img")

  if images.length > 0 {
    for i in 0 to images.length - 1 {
      let image = images->WebAPI.NodeList.item(i)->Null.getOrThrow->imageFromElement
      await image->WebAPI.HTMLImageElement.decode
    }
  }
}
