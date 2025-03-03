type social = X(string) | Bluesky(string)

type author = {
  username: string,
  fullname: string,
  role: string,
  imgUrl: string,
  social: social,
}

let authors = [
  {
    username: "hongbo",
    fullname: "Hongbo Zhang",
    role: "Compiler & Build System",
    imgUrl: "https://pbs.twimg.com/profile_images/1369548222314598400/E2y46vrB_400x400.jpg",
    social: X("bobzhang1988"),
  },
  {
    username: "chenglou",
    fullname: "Cheng Lou",
    role: "Syntax & Tools",
    imgUrl: "https://pbs.twimg.com/profile_images/554199709909131265/Y5qUDaCB_400x400.jpeg",
    social: X("_chenglou"),
  },
  {
    username: "maxim",
    fullname: "Maxim Valcke",
    role: "Syntax Lead",
    imgUrl: "https://pbs.twimg.com/profile_images/970271048812974080/Xrr8Ob6J_400x400.jpg",
    social: X("_binary_search"),
  },
  {
    username: "ryyppy",
    fullname: "Patrick Ecker",
    role: "Documentation",
    imgUrl: "https://pbs.twimg.com/profile_images/1388426717006544897/B_a7D4GF_400x400.jpg",
    social: X("ryyppy"),
  },
  {
    username: "rickyvetter",
    fullname: "Ricky Vetter",
    role: "ReScript & React",
    imgUrl: "https://pbs.twimg.com/profile_images/541111032207273984/DGsZmmfr_400x400.jpeg",
    social: X("rickyvetter"),
  },
  {
    username: "made_by_betty",
    fullname: "Bettina Steinbrecher",
    role: "Brand / UI / UX",
    imgUrl: "https://pbs.twimg.com/profile_images/1366785342704136195/3IGyRhV1_400x400.jpg",
    social: X("made_by_betty"),
  },
  {
    username: "rescript-team",
    fullname: "ReScript Team",
    role: "Core Development",
    imgUrl: "https://pbs.twimg.com/profile_images/1358354824660541440/YMKNWE1V_400x400.png",
    social: X("rescriptlang"),
  },
  {
    username: "rescript-association",
    fullname: "ReScript Association",
    role: "Foundation",
    imgUrl: "https://pbs.twimg.com/profile_images/1045362176117100545/MioTQoTp_400x400.jpg",
    social: X("ReScriptAssoc"),
  },
  {
    username: "josh-derocher-vlk",
    fullname: "Josh Derocher-Vlk",
    role: "Community Member",
    imgUrl: "https://cdn.bsky.app/img/avatar/plain/did:plc:erifxn5qcos2zrxvogse5y5s/bafkreif6v7lrtz24vi5ekumkiwg7n7js55coekszduwhjegfmdopd7tqmi@webp",
    social: Bluesky("vlkpack.com"),
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
  originalSrc: Null.t<string>,
  originalSrcUrl: Null.t<string>,
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
    originalSrc: json->optional(field("originalSrc", string, ...), _)->Null.fromOption,
    originalSrcUrl: json->optional(field("originalSrcUrl", string, ...), _)->Null.fromOption,
  } {
  | fm => Ok(fm)
  | exception DecodeError(str) => Error(str)
  | exception AuthorNotFound(str) => Error(str)
  }
}
