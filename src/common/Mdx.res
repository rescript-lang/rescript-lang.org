/*
  Abstract type for representing mdx
  components mostly passed as children to
  the component context API
 */
type mdxComponent

external fromReactElement: React.element => mdxComponent = "%identity"

external arrToReactElement: array<mdxComponent> => React.element = "%identity"

/* Useful for getting the type of a certain mdx component, such as
   "inlineCode" | "p" | "ul" | etc.

   Will return "unknown" if either given element is not an mdx component,
   or if there is no mdxType property found */
let getMdxType: mdxComponent => string = %raw("element => {
      if(element == null || element.props == null) {
        return 'unknown';
      }
      return element.props.mdxType;
    }")

let getMdxClassName: mdxComponent => option<string> = %raw("element => {
      if(element == null || element.props == null) {
        return;
      }
      return element.props.className;
    }")

module MdxChildren = {
  type unknown

  type t

  type case =
    | String(string)
    | Element(mdxComponent)
    | Array(array<mdxComponent>)
    | Unknown(unknown)

  let classify = (v: t): case =>
    if %raw(`function (a) { return  a instanceof Array}`)(v) {
      Array((Obj.magic(v): array<mdxComponent>))
    } else if typeof(v) == #string {
      String((Obj.magic(v): string))
    } else if typeof(v) == #object {
      Element((Obj.magic(v): mdxComponent))
    } else {
      Unknown((Obj.magic(v): unknown))
    }

  external toReactElement: t => React.element = "%identity"

  // Sometimes an mdxComponent element can be a string
  // which means it doesn't have any children.
  // We will return the element as its own child then
  let getMdxChildren: mdxComponent => t = %raw("element => {
      if(typeof element === 'string') {
        return element;
      }
      if(element == null || element.props == null || element.props.children == null) {
        return;
      }
      return element.props.children;
    }")
}

module Components = {
  // Used for reflection based logic in
  // components such as `code` or `ul`
  // with runtime reflection
  type unknown
}
