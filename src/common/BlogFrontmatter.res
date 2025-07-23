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
    imgUrl: "",
    social: X("bobzhang1988"),
  },
  {
    username: "chenglou",
    fullname: "Cheng Lou",
    role: "Syntax & Tools",
    imgUrl: "",
    social: X("_chenglou"),
  },
  {
    username: "maxim",
    fullname: "Maxim Valcke",
    role: "Syntax Lead",
    imgUrl: "",
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
    | Community

  let toString = (c: t): string =>
    switch c {
    | Release => "Release"
    | Testing => "Testing"
    | Preview => "Preview"
    | Roadmap => "Roadmap"
    | Community => "Community"
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
  | "community" => Community
  | str => throw(Failure(`Unknown category "${str}"`))
  }

exception AuthorNotFound(string)

let decodeAuthor = (~fieldName: string, ~authors, username) =>
  switch Array.find(authors, a => a.username === username) {
  | Some(author) => author
  | None => throw(AuthorNotFound(`Couldn't find author "${username}" in field ${fieldName}`))
  }

let decode = (json: JSON.t): result<t, string> => {
  open JSON
  switch json {
  | Object(dict{
      "author": String(author),
      "co_authors": ?co_authors,
      "date": String(date),
      "badge": ?badge,
      "previewImg": ?previewImg,
      "articleImg": ?articleImg,
      "title": String(title),
      "description": ?description,
    }) =>
    let author = decodeAuthor(~fieldName="author", ~authors, author)
    let co_authors = switch co_authors {
    | Some(Array(co_authors)) =>
      co_authors->Array.filterMap(a =>
        switch a {
        | String(a) => decodeAuthor(~fieldName="co-authors", ~authors, a)->Some
        | _ => None
        }
      )
    | _ => []
    }
    let date = date->DateStr.fromString
    let badge = switch badge {
    | Some(String(badge)) => badge->decodeBadge->Null.Value
    | _ => Null
    }
    let previewImg = switch previewImg {
    | Some(String(previewImg)) => previewImg->Null.Value
    | _ => Null
    }
    let articleImg = switch articleImg {
    | Some(String(articleImg)) => articleImg->Null.Value
    | _ => Null
    }
    let description = switch description {
    | Some(String(description)) => description->Null.Value
    | _ => Null
    }
    Ok({
      author,
      co_authors,
      date,
      previewImg,
      articleImg,
      title,
      badge,
      description,
    })
  | exception AuthorNotFound(str) => Error(str)
  | _ => Error(`Failed to decode: ${JSON.stringify(json)}`)
  }
}
