type t

@module("docson") external docson: t = "default"

@set external setTemplateBaseUrl: (t, string) => unit = "templateBaseUrl"

@module("docson") @scope("default")
external doc: (string, JSON.t, option<string>, string) => unit = "doc"

@react.component
let make = (~tag) => {
  let element = React.useRef(Nullable.null)

  React.useEffect(() => {
    let segment = `https://raw.githubusercontent.com/rescript-lang/rescript/${tag}/docs/docson/build-schema.json`

    // The api for docson is a little bit funky, so you need to check out the source to understand what it's doing
    // See: https://github.com/lbovet/docson/blob/master/src/index.js
    let _ =
      fetch(segment)
      ->Promise.then(WebAPI.Response.json)
      ->Promise.then(schema => {
        let _ = switch element.current->Nullable.toOption {
        | Some(_el) =>
          setTemplateBaseUrl(docson, "/docson")

          doc("docson-root", schema, None, segment)

        | None => ()
        }
        Promise.resolve()
      })
      ->Promise.catch(err => {
        Console.error2("Failed to load docson schema", err)
        Promise.resolve()
      })

    None
  }, [])
  <div ref={ReactDOM.Ref.domRef(element)} id="docson-root" />
}
