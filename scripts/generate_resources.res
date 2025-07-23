/** This is the list of community content we want to generate. */
/** If you  have content you would like to add, please open up a PR adding the link to this list and then run `npm run generate-resources` */
let urls = [
  // 2025
  "https://dev.to/dzakh/javascript-schema-library-from-the-future-5420",
  "https://www.youtube.com/watch?v=yKl2fSdnw7w",
  "https://github.com/rescript-lang/awesome-rescript", // regardless of age this seems like it should always be near the top
  // 2024
  "https://www.youtube.com/watch?v=MC-dbM-GEuw",
  "https://dev.to/jderochervlk/rescript-has-come-a-long-way-maybe-its-time-to-switch-from-typescript-29he",
  "https://www.youtube.com/watch?v=f0gDMjuaCZo",
  "https://www.geldata.com/blog/rescript-and-edgedb",
  "https://www.youtube.com/watch?v=37FY6a-zY20",
  // 2023
  "https://dev.to/cometkim/when-and-where-to-use-rescript-the-rescript-happy-path-47ni",
  // 2022
  "https://www.greyblake.com/blog/from-typescript-to-rescript/",
  "https://dev.to/zth/getting-rid-of-your-dead-code-in-rescript-3mba",
  "https://www.youtube.com/watch?v=KDL-kRgilkQ",
  "https://dev.to/srikanthkyatham/rescript-react-error-boundary-usage-3b05",
  // "https://www.daggala.com/belt_vs_js_array_in_rescript/" I think we should exclude this one since it's related to API we are deprecating
  // 2021
  "https://fullsteak.dev/posts/fullstack-rescript-architecture-overview",
  "https://scalac.io/blog/rescript-for-react-development/",
  "https://yangdanny97.github.io/blog/2021/07/09/Migrating-to-Rescript",
  "https://alexfedoseev.com/blog/post/responsive-images-and-cumulative-layout-shift",
  "https://dev.to/ryyppy/rescript-records-nextjs-undefined-and-getstaticprops-4890",
]

let generate = async () => {
  let filePath = "data/resources.json"
  let metaData = await MetaTagsApi.getMetaTags(urls)

  let fileContent = `${metaData
    ->Array.map(i =>
      {
        "title": `${i.title->Option.getOr("")}`,
        "description": `${i.description->Option.getOr("")}`,
        "image": `${i.image->Option.getOr("")}`,
        "url": `${i.url}`,
      }
    )
    ->JSON.stringifyAny
    ->Option.getOr("[]")}
  `

  Node.Fs.writeFileSync(filePath, fileContent)
}

await generate()
