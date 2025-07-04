type t = {
  title: string,
  metaTitle: Null.t<string>,
  description: Null.t<string>,
  canonical: Null.t<string>,
}

let decode = json => {
  open JSON
  switch json {
  | Object(dict{
      "title": String(title),
      "metaTitle": ?metaTitle,
      "description": ?description,
      "canonical": ?canonical,
    }) =>
    Some({
      title,
      metaTitle: switch metaTitle {
      | Some(String(v)) => Null.Value(v)
      | _ => Null.Null
      },
      description: switch description {
      | Some(String(v)) => Null.Value(v)
      | _ => Null.Null
      },
      canonical: switch canonical {
      | Some(String(v)) => Null.Value(v)
      | _ => Null.Null
      },
    })
  | _ => None
  }
}
