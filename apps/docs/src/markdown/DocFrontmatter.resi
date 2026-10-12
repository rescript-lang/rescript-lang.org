type t = {
  title: string,
  metaTitle: Null.t<string>, // If there's no metaTitle, we will take title instead
  description: Null.t<string>,
  canonical: Null.t<string>,
}

let decode: JSON.t => option<t>
