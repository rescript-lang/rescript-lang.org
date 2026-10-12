let getField = (frontmatter: JSON.t, key: string) =>
  switch frontmatter {
  | Object(dict) =>
    switch dict->Dict.get(key) {
    | Some(String(s)) => s
    | _ => ""
    }
  | _ => ""
  }
