/*
Docson is a tool to render a json schema via client side JS.

Here is a list of files needed by this component:
- Build schema is found in data/build-schema.json
- Templates for rendering the content can be found in public/docson/.
- Styles can be found in styles/docson.css

Please note that this component cannot be rendered on SSR, so use it in conjunction with
Next's dynamic import mechanism.
*/

@react.component
let make: (~tag: string) => React.element
