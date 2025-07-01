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

    let nodesArray = []

    for i in 0 to nodeList.length {
      let node = WebAPI.NodeList.item(nodeList, i)
      nodesArray->Array.push(node)
    }

    let metaTags = nodesArray->Array.reduce(Dict.fromArray([]), (tags, meta) => {
      let name = meta->Obj.magic->WebAPI.Element.getAttribute("name")

      let content = meta->Obj.magic->WebAPI.Element.getAttribute("content")
      tags->Dict.set(name, content)
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
