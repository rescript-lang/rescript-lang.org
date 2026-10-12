type t = {
  title: string,
  metaTitle: Null.t<string>,
  description: Null.t<string>,
  canonical: Null.t<string>,
}

let decode = json => {
  open JSON
  let optionToNull = opt =>
    switch opt {
    | Some(String(v)) => Null.Value(v)
    | _ => Null
    }
  switch json {
  | Object(dict{
      "title": String(title),
      "metaTitle": ?metaTitle,
      "description": ?description,
      "canonical": ?canonical,
    }) =>
    Some({
      title,
      metaTitle: metaTitle->optionToNull,
      description: description->optionToNull,
      canonical: canonical->optionToNull,
    })
  | _ => None
  }
}
