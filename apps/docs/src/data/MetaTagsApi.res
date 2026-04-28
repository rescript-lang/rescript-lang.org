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
  try {
    let response = await fetch(url)

    let html = await response->WebAPI.Response.text
    let dom = Jsdom.make(html)
    let document = dom.window.document

    let nodeList = document->WebAPI.Document.querySelectorAll("meta")

    let elements = []

    for i in 0 to nodeList.length {
      let node = WebAPI.NodeList.item(nodeList, i)
      // cast Node elements to Element
      elements->Array.push((Obj.magic(node): WebAPI.DOMAPI.element))
    }

    let metaTags = elements->Array.reduce(Dict.fromArray([]), (tags, meta) => {
      let name = meta->WebAPI.Element.getAttribute("name")
      let property = meta->WebAPI.Element.getAttribute("property")
      let itemprop = meta->WebAPI.Element.getAttribute("itemprop")

      let name = switch (name, property, itemprop) {
      | (Value(name), _, _) => Some(name)
      | (_, Value(property), _) => Some(property)
      | (_, _, Value(itemprop)) => Some(itemprop)
      | _ => None
      }

      let content = meta->WebAPI.Element.getAttribute("content")

      switch (name, content) {
      | (Some(name), Value(content)) => tags->Dict.set(name, content)
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
