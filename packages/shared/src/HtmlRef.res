/** For refs attached to HTML tags; bridge React's DOM type to WebAPI's HTML type. */
external fromDom: Dom.element => WebAPI.DOMAPI.htmlElement = "%identity"

let domRef = ref =>
  ReactDOM.Ref.callbackDomRef(element => {
    ref.React.current = element->Nullable.map(fromDom)
    None
  })

let elementRef = ref =>
  ReactDOM.Ref.callbackDomRef(element => {
    ref.React.current =
      element->Nullable.map(element => fromDom(element)->WebAPI.HTMLElement.asElement)
    None
  })
