type t = {
  title: option<string>,
  description: option<string>,
  image: option<string>,
}

/**
 This function uses JSDOM to fetch a webpage and extract the meta tags from it. 
 JSDOM is required since this runs on Node.
 */
let extractMetaTags = async (url: string) => {
  open Webapi
  try {
    let response = await Fetch.fetch(url)

    let html = await response->Fetch.Response.text
    let dom = Jsdom.make(html)
    let document = dom.window.document

    let metaTags =
      document
      ->Document.querySelectorAll("meta")
      ->Array.fromArrayLike
      ->Array.reduce(Dict.fromArray([]), (tags, meta) => {
        let name = meta->Element.getAttribute("name")->Nullable.toOption
        let property = meta->Element.getAttribute("property")->Nullable.toOption
        let itemprop = meta->Element.getAttribute("itemprop")->Nullable.toOption

        let name = switch (name, property, itemprop) {
        | (Some(name), _, _) => Some(name)
        | (_, Some(property), _) => Some(property)
        | (_, _, Some(itemprop)) => Some(itemprop)
        | _ => None
        }

        let content = meta->Element.getAttribute("content")->Nullable.toOption

        switch (name, content) {
        | (Some(name), Some(content)) => tags->Dict.set(name, content)
        | _ => ()
        }

        tags
      })

    let title = metaTags->Dict.get("og:title")
    let description = metaTags->Dict.get("og:description")
    let image = metaTags->Dict.get("og:image")

    Some({
      title,
      description,
      image,
    })
  } catch {
  | _ => {
      Console.error(`Error fetching Open Graph details for ${url}`)
      None
    }
  }
}

type tags = {
  ...t,
  url: string,
}

/*
 Pass an array of URLs and get back an array of meta tags for each URL.
 */
let getMetaTags = async (urls: array<string>) => {
  let metaTags: array<tags> = []
  for i in 0 to Array.length(urls) - 1 {
    let url = urls[i]
    switch url {
    | Some(url) => {
        let tags = await extractMetaTags(url)
        switch tags {
        | Some(tags) =>
          metaTags->Array.push({
            title: tags.title,
            description: tags.description,
            image: tags.image,
            url,
          })
        | None => ()
        }
      }
    | None => ()
    }
  }
  metaTags
}
