type author = {
  username: string,
  fullname: string,
  role: string,
  imgUrl: string,
  xHandle: string,
}

let authors = [
  {
    username: "hongbo",
    fullname: "Hongbo Zhang",
    role: "Compiler & Build System",
    imgUrl: "https://pbs.twimg.com/profile_images/1369548222314598400/E2y46vrB_400x400.jpg",
    xHandle: "bobzhang1988",
  },
  {
    username: "chenglou",
    fullname: "Cheng Lou",
    role: "Syntax & Tools",
    imgUrl: "https://pbs.twimg.com/profile_images/554199709909131265/Y5qUDaCB_400x400.jpeg",
    xHandle: "_chenglou",
  },
  {
    username: "maxim",
    fullname: "Maxim Valcke",
    role: "Syntax Lead",
    imgUrl: "https://pbs.twimg.com/profile_images/970271048812974080/Xrr8Ob6J_400x400.jpg",
    xHandle: "_binary_search",
  },
  {
    username: "ryyppy",
    fullname: "Patrick Ecker",
    role: "Documentation",
    imgUrl: "https://pbs.twimg.com/profile_images/1388426717006544897/B_a7D4GF_400x400.jpg",
    xHandle: "ryyppy",
  },
  {
    username: "rickyvetter",
    fullname: "Ricky Vetter",
    role: "ReScript & React",
    imgUrl: "https://pbs.twimg.com/profile_images/541111032207273984/DGsZmmfr_400x400.jpeg",
    xHandle: "rickyvetter",
  },
  {
    username: "made_by_betty",
    fullname: "Bettina Steinbrecher",
    role: "Brand / UI / UX",
    imgUrl: "https://pbs.twimg.com/profile_images/1366785342704136195/3IGyRhV1_400x400.jpg",
    xHandle: "made_by_betty",
  },
  {
    username: "rescript-team",
    fullname: "ReScript Team",
    role: "Core Development",
    imgUrl: "https://pbs.twimg.com/profile_images/1358354824660541440/YMKNWE1V_400x400.png",
    xHandle: "rescriptlang",
  },
  {
    username: "rescript-association",
    fullname: "ReScript Association",
    role: "Foundation",
    imgUrl: "https://pbs.twimg.com/profile_images/1045362176117100545/MioTQoTp_400x400.jpg",
    xHandle: "ReScriptAssoc",
  },
]

module Badge = {
  type t =
    | Release
    | Testing
    | Preview
    | Roadmap

  let toString = (c: t): string =>
    switch c {
    | Release => "Release"
    | Testing => "Testing"
    | Preview => "Preview"
    | Roadmap => "Roadmap"
    }
}

type t = {
  author: author,
  co_authors: array<author>,
  date: DateStr.t,
  previewImg: Null.t<string>,
  articleImg: Null.t<string>,
  title: string,
  badge: Null.t<Badge.t>,
  description: Null.t<string>,
}

let decodeBadge = (str: string): Badge.t =>
  switch String.toLowerCase(str) {
  | "release" => Release
  | "testing" => Testing
  | "preview" => Preview
  | "roadmap" => Roadmap
  | str => raise(Json.Decode.DecodeError(`Unknown category "${str}"`))
  }

exception AuthorNotFound(string)

let decodeAuthor = (~fieldName: string, ~authors, username) =>
  switch Array.find(authors, a => a.username === username) {
  | Some(author) => author
  | None => raise(AuthorNotFound(`Couldn't find author "${username}" in field ${fieldName}`))
  }

let authorDecoder = (~fieldName: string, ~authors) => {
  open Json.Decode

  let multiple = j => array(string, j)->Array.map(a => decodeAuthor(~fieldName, ~authors, a))

  let single = j => [string(j)->decodeAuthor(~fieldName, ~authors)]

  either(single, multiple)
}

let decode = (json: JSON.t): result<t, string> => {
  open Json.Decode
  switch {
    author: json->field("author", string, _)->decodeAuthor(~fieldName="author", ~authors),
    co_authors: json
    ->optional(field("co-authors", authorDecoder(~fieldName="co-authors", ~authors), ...), _)
    ->Option.getOr([]),
    date: json->field("date", string, _)->DateStr.fromString,
    badge: json->optional(j => field("badge", string, j)->decodeBadge, _)->Null.fromOption,
    previewImg: json->optional(field("previewImg", string, ...), _)->Null.fromOption,
    articleImg: json->optional(field("articleImg", string, ...), _)->Null.fromOption,
    title: json->(field("title", string, _)),
    description: json->(nullable(field("description", string, ...), _)),
  } {
  | fm => Ok(fm)
  | exception DecodeError(str) => Error(str)
  | exception AuthorNotFound(str) => Error(str)
  }
}
