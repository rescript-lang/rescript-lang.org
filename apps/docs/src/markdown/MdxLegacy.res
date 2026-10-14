type props = {
  children?: React.element,
  className?: string,
  metastring?: string,
  mdxType?: string,
}

@get external props: React.element => props = "props"

let getChildren = element =>
  React.isValidElement(element) ? props(element).children->Option.getOr(React.null) : element

let getClassName = element => React.isValidElement(element) ? props(element).className : None

let getMetastring = element => React.isValidElement(element) ? props(element).metastring : None

type component
@get external elementType: React.element => component = "type"

let getType = element => {
  if React.isValidElement(element) {
    switch props(element).mdxType {
    | Some(tag) => tag
    | None => {
        let tag = elementType(element)
        typeof(tag) == #string ? String.make(tag) : "unknown"
      }
    }
  } else {
    "unknown"
  }
}

@get external component: React.element => React.componentLike<'props, React.element> = "type"
let isComponent = (element, make) => React.isValidElement(element) && component(element) === make
