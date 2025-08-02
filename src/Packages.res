//
// TODO:
// -
// - Whitelist @reason-association
// - filter bs- prefixed packages (!???)
// - put official / non-official processing on the server side?
//

type urlResource = {
  name: string,
  keywords: array<string>,
  description: string,
  urlHref: string,
  official: bool,
}

external unsafeToUrlResource: JSON.t => array<urlResource> = "%identity"

type npmPackage = {
  name: string,
  version: string,
  keywords: array<string>,
  description: string,
  repositoryHref: Null.t<string>,
  npmHref: string,
  searchScore: float,
  maintenanceScore: float,
}

// These are packages that we do not want to filter out when loading searching from NPM.
let packageAllowList: array<string> = []

module Resource = {
  type t = Npm(npmPackage) | Url(urlResource) | Outdated(npmPackage)

  let getId = (res: t) => {
    switch res {
    | Npm({name})
    | Outdated({name})
    | Url({name}) => name
    }
  }

  let shouldFilter = (res: t) => {
    switch res {
    | Npm(pkg) | Outdated(pkg) =>
      if pkg.name->String.startsWith("@elm-react") {
        true
      } else if pkg.name->String.startsWith("bs-") {
        true
      } else if (
        pkg.name->String.startsWith("@reason-react-native") ||
          pkg.name->String.startsWith("reason-react-native")
      ) {
        true
      } else {
        false
      }
    | Url(_) => false
    }
  }

  let filterKeywords = (keywords: array<string>): array<string> => {
    Array.filter(keywords, kw => {
      switch String.toLowerCase(kw) {
      | "reasonml"
      | "reason"
      | "ocaml"
      | "bucklescript"
      | "rescript" => false
      | _ => true
      }
    })
  }

  let uniqueKeywords = arr => arr->Set.fromArray->Set.toArray

  let isOfficial = (res: t) => {
    switch res {
    | Npm(pkg) | Outdated(pkg) =>
      pkg.name === "rescript" || pkg.name->String.startsWith("@rescript/") || pkg.name === "gentype"
    | Url(urlRes) => urlRes.official
    }
  }

  let applyNpmSearch = (packages: array<npmPackage>, pattern: string): array<
    Fuse.match<npmPackage>,
  > => {
    let fuseOpts = Fuse.Options.t(
      ~shouldSort=true,
      ~includeScore=true,
      ~threshold=0.2,
      ~ignoreLocation=true,
      ~minMatchCharLength=1,
      ~keys=["meta.uid", "name", "keywords"],
      (),
    )

    let fuser = Fuse.make(packages, fuseOpts)

    fuser
    ->Fuse.search(pattern)
    ->Array.toSorted((a, b) => Float.compare(a["item"].searchScore, b["item"].searchScore))
  }

  let applyUrlResourceSearch = (urls: array<urlResource>, pattern: string): array<
    Fuse.match<urlResource>,
  > => {
    let fuseOpts = Fuse.Options.t(
      ~shouldSort=true,
      ~includeScore=true,
      ~threshold=0.2,
      ~ignoreLocation=true,
      ~minMatchCharLength=1,
      ~keys=["name", "keywords"],
      (),
    )

    let fuser = Fuse.make(urls, fuseOpts)

    fuser->Fuse.search(pattern)
  }

  let applySearch = (resources: array<t>, pattern: string): array<t> => {
    let (allNpms, allUrls, allOutDated) = Array.reduce(resources, ([], [], []), (acc, next) => {
      let (npms, resources, outdated) = acc

      switch next {
      | Npm(pkg) => Array.push(npms, pkg)->ignore
      | Url(res) => Array.push(resources, res)->ignore
      | Outdated(pkg) => Array.push(outdated, pkg)->ignore
      }
      (npms, resources, outdated)
    })

    let filteredNpm = applyNpmSearch(allNpms, pattern)->Array.map(m => Npm(m["item"]))
    let filteredUrls = applyUrlResourceSearch(allUrls, pattern)->Array.map(m => Url(m["item"]))
    let filteredOutdated = applyNpmSearch(allOutDated, pattern)->Array.map(m => Outdated(m["item"]))

    Belt.Array.concatMany([filteredNpm, filteredUrls, filteredOutdated])
  }
}

module Card = {
  @react.component
  let make = (~value: Resource.t, ~onKeywordSelect: option<string => unit>=?) => {
    let icon = switch value {
    | Npm(_) | Outdated(_) => <Icon.Npm className="w-8 opacity-50" />
    | Url(_) =>
      <span>
        <Icon.Hyperlink className="w-8 opacity-50" />
      </span>
    }
    let linkBox = switch value {
    | Npm(pkg) | Outdated(pkg) =>
      let repositoryHref = Null.toOption(pkg.repositoryHref)
      let repoEl = switch repositoryHref {
      | Some(href) =>
        let name = if String.startsWith(href, "https://github.com") {
          "GitHub"
        } else if String.startsWith(href, "https://gitlab.com") {
          "GitLab"
        } else {
          "Repository"
        }
        <>
          <span> {React.string("|")} </span>
          <a href rel="noopener noreferrer" className="hover:text-fire"> {React.string(name)} </a>
        </>
      | None => React.null
      }
      <div className="text-14 space-x-2 mt-1">
        <a className="hover:text-fire" href={pkg.npmHref}> {React.string("NPM")} </a>
        {repoEl}
      </div>
    | Url(_) => React.null
    }

    let titleHref = switch value {
    | Npm(pkg) | Outdated(pkg) => pkg.repositoryHref->Null.toOption->Option.getOr(pkg.npmHref)
    | Url(res) => res.urlHref
    }

    let (title, description, keywords) = switch value {
    | Npm({name, description, keywords})
    | Outdated({name, description, keywords})
    | Url({name, description, keywords}) => (name, description, keywords)
    }

    <div className="bg-gray-5-tr py-6 rounded-lg p-4">
      <div className="flex justify-between">
        <div>
          <a className="font-bold hover:text-fire text-18" href=titleHref>
            <span> {React.string(title)} </span>
          </a>
          {linkBox}
        </div>
        <div> {icon} </div>
      </div>
      <div className="mt-4 text-16"> {React.string(description)} </div>
      <div className="space-x-2 mt-4">
        {Array.map(keywords, keyword => {
          let onMouseDown = Option.map(onKeywordSelect, cb => {
            evt => {
              ReactEvent.Mouse.preventDefault(evt)
              cb(keyword)
            }
          })
          <button
            ?onMouseDown
            className="hover:pointer px-2 rounded-lg text-white bg-fire-70 text-14"
            key={keyword}>
            {React.string(keyword)}
          </button>
        })->React.array}
      </div>
    </div>
  }
}

module Category = {
  type t =
    | Official
    | Community

  let toString = t =>
    switch t {
    | Official => "Official Resources"
    | Community => "Community Resources"
    }

  @react.component
  let make = (~title: string, ~children) => {
    <div>
      <h3 className="font-sans font-medium text-gray-100 tracking-wide text-14 uppercase mb-2">
        {React.string(title)}
      </h3>
      <div> children </div>
    </div>
  }
}

module Filter = {
  type t = {
    searchterm: string,
    includeOfficial: bool,
    includeCommunity: bool,
    includeNpm: bool,
    includeUrlResource: bool,
    includeOutdated: bool,
  }
}

module InfoSidebar = {
  module Toggle = {
    @react.component
    let make = (~enabled, ~toggle, ~children) => {
      let className = "block px-4 rounded-lg " ++ (enabled ? "bg-fire text-white" : " bg-gray-10")

      let onMouseDown = evt => {
        ReactEvent.Mouse.preventDefault(evt)
        toggle()
      }

      <button onMouseDown className> children </button>
    }
  }

  @react.component
  let make = (~setFilter: (Filter.t => Filter.t) => unit, ~filter: Filter.t) => {
    let h2 = "group mb-3 text-14 uppercase  leading-tight font-sans font-medium text-gray-80"
    let link = "hover:underline"

    <aside className=" border-l-2 p-4 py-12 border-fire-30 space-y-16">
      <div>
        <h2 className=h2> {React.string("Include")} </h2>
        <div className="space-y-2">
          <Toggle
            enabled={filter.includeOfficial}
            toggle={() => {
              setFilter(prev => {
                {...prev, Filter.includeOfficial: !filter.includeOfficial}
              })
            }}>
            {React.string("Official")}
          </Toggle>
          <Toggle
            enabled={filter.includeCommunity}
            toggle={() => {
              setFilter(prev => {
                {...prev, Filter.includeCommunity: !filter.includeCommunity}
              })
            }}>
            {React.string("Community")}
          </Toggle>
          <Toggle
            enabled={filter.includeNpm}
            toggle={() => {
              setFilter(prev => {
                {...prev, Filter.includeNpm: !filter.includeNpm}
              })
            }}>
            {React.string("NPM package")}
          </Toggle>
          <Toggle
            enabled={filter.includeUrlResource}
            toggle={() => {
              setFilter(prev => {
                {...prev, Filter.includeUrlResource: !filter.includeUrlResource}
              })
            }}>
            {React.string("URL resources")}
          </Toggle>
          <Toggle
            enabled={filter.includeOutdated}
            toggle={() => {
              setFilter(prev => {
                {...prev, Filter.includeOutdated: !filter.includeOutdated}
              })
            }}>
            {React.string("Outdated")}
          </Toggle>
        </div>
      </div>
      <div>
        <h2 className=h2> {React.string("Guidelines")} </h2>
        <ul className="space-y-4">
          <Next.Link href="/docs/guidelines/publishing-packages" className=link>
            {React.string("Publishing ReScript npm packages")}
          </Next.Link>
          /* <li> */
          /* <Next.Link href="/docs/guidelines/writing-bindings"  className=link> */
          /* {React.string("Writing Bindings & Libraries")} */
          /* </Next.Link> */
          /* </li> */
        </ul>
      </div>
    </aside>
  }
}

type props = {
  packages: array<npmPackage>,
  urlResources: array<urlResource>,
  unmaintained: array<npmPackage>,
}

type state =
  | All
  | Filtered(string) // search term

let default = (props: props) => {
  open Markdown

  let (state, setState) = React.useState(_ => All)

  let (filter, setFilter) = React.useState(_ => {
    Filter.searchterm: "",
    includeOfficial: true,
    includeCommunity: true,
    includeNpm: true,
    includeUrlResource: true,
    includeOutdated: false,
  })

  let allResources = {
    let npms = props.packages->Array.map(pkg => Resource.Npm(pkg))
    let urls = props.urlResources->Array.map(res => Resource.Url(res))
    let outdated = props.unmaintained->Array.map(pkg => Resource.Outdated(pkg))
    Belt.Array.concatMany([npms, urls, outdated])
  }

  let resources = switch state {
  | All => allResources
  | Filtered(pattern) => Resource.applySearch(allResources, pattern)
  }

  let onValueChange = value => {
    setState(_ => {
      switch value {
      | "" => All
      | value => Filtered(value)
      }
    })
  }

  let searchValue = switch state {
  | All => ""
  | Filtered(value) => value
  }

  let onClear = () => {
    setState(_ => All)
  }

  let (officialResources, communityResources) = Array.reduce(resources, ([], []), (acc, next) => {
    let (official, community) = acc
    let isResourceIncluded = switch next {
    | Npm(_) => filter.includeNpm
    | Url(_) => filter.includeUrlResource
    | Outdated(_) => filter.includeOutdated && filter.includeNpm
    }
    if !isResourceIncluded {
      ()
    } else if filter.includeOfficial && Resource.isOfficial(next) {
      Array.push(official, next)->ignore
    } else if filter.includeCommunity && !Resource.shouldFilter(next) {
      Array.push(community, next)->ignore
    }
    (official, community)
  })

  let onKeywordSelect = keyword => {
    WebAPI.Window.scrollTo(window, ~options={left: 0.0, top: 0.0, behavior: Smooth})
    setState(_ => {
      Filtered(keyword)
    })
  }

  let officialCategory = switch officialResources {
  | [] => React.null
  | resources =>
    <Category title={Category.toString(Official)}>
      <div className="space-y-4">
        {Array.map(resources, res => {
          <Card key={Resource.getId(res)} onKeywordSelect value={res} />
        })->React.array}
      </div>
    </Category>
  }

  let communityCategory = switch communityResources {
  | [] => React.null
  | resources =>
    <Category title={Category.toString(Community)}>
      <div className="space-y-4">
        {Array.map(resources, res => {
          <Card onKeywordSelect key={Resource.getId(res)} value={res} />
        })->React.array}
      </div>
    </Category>
  }

  let router = Next.Router.useRouter()

  // On first render, the router query is undefined so we set a flag.
  let firstRenderDone = React.useRef(false)

  React.useEffect(() => {
    firstRenderDone.current = true
    None
  }, [])

  // On second render, this hook runs one more time to actually trigger the search.
  React.useEffect(() => {
    router.query->Dict.get("search")->Option.forEach(onValueChange)

    None
  }, [firstRenderDone.current])

  let updateQuery = value =>
    router->Next.Router.replaceObj({
      pathname: router.pathname,
      query: value === "" ? Dict.make() : Dict.fromArray([("search", value)]),
    })

  // When the search term changes, update the router query accordingly.
  React.useEffect(() => {
    switch state {
    | All => updateQuery("")
    | Filtered(value) => updateQuery(value)
    }

    None
  }, [state])

  let (isOverlayOpen, setOverlayOpen) = React.useState(() => false)
  <>
    <Meta
      siteName="ReScript Packages"
      title="Package Index | ReScript Documentation"
      description="Official and unofficial resources, libraries and bindings for ReScript"
    />
    <div className="mt-16 pt-2">
      <div className="text-gray-80 text-18">
        <Navigation isOverlayOpen setOverlayOpen />
        <div className="flex overflow-hidden">
          <div
            className="flex justify-between min-w-320 px-4 pt-16 lg:align-center w-full lg:px-8 pb-48">
            <MdxProvider components=MarkdownComponents.default>
              <main className="max-w-1280 w-full flex justify-center">
                <div className="w-full max-w-176.25">
                  <H1> {React.string("Libraries & Bindings")} </H1>
                  <SearchBox
                    placeholder="Enter a search term, name, keyword, etc"
                    onValueChange
                    onClear
                    value={searchValue}
                  />
                  <div className="mt-12 space-y-8">
                    officialCategory
                    communityCategory
                  </div>
                </div>
              </main>
              <div className="hidden lg:block h-full ">
                <InfoSidebar filter setFilter />
              </div>
            </MdxProvider>
          </div>
        </div>
        <Footer />
      </div>
    </div>
  </>
}

let parsePkgs = data => {
  open JSON

  switch data {
  | Object(dict{"objects": Array(arr)}) =>
    arr->Array.filterMap(pkg => {
      switch pkg {
      | Object(dict{
          "searchScore": Number(searchScore),
          "score": Object(dict{"detail": Object(dict{"maintenance": Number(maintenanceScore)})}),
          "package": Object(dict{
            "name": String(name),
            "keywords": Array(keywords),
            "version": String(version),
            "description": ?Some(String(description)),
            "links": Object(dict{
              "npm": String(npmHref),
              "repository": ?Some(String(repositoryHref)),
            }),
          }),
        }) =>
        let keywords =
          keywords
          ->Array.filterMap(k => {
            switch k {
            | String(k) => Some(k)
            | _ => None
            }
          })
          ->Resource.filterKeywords
          ->Resource.uniqueKeywords

        Some({
          name,
          version,
          keywords,
          description,
          repositoryHref: repositoryHref->Null.make,
          npmHref,
          searchScore,
          maintenanceScore,
        })
      | _ => None
      }
    })
  | _ => []
  }
}

let getStaticProps: Next.GetStaticProps.t<props, unit> = async _ctx => {
  let baseUrl = "https://registry.npmjs.org/-/v1/search?text=keywords:rescript&size=250&maintenance=1.0&popularity=0.5&quality=0.9"

  let (one, two, three) = await Promise.all3((
    fetch(baseUrl),
    fetch(baseUrl ++ "&from=250"),
    fetch(baseUrl ++ "&from=500"),
  ))

  let responseToOption = async response => {
    try {
      let json = await response->WebAPI.Response.json
      Some(json)
    } catch {
    | _ =>
      Console.error2("Failed to parse response", response)
      None
    }
  }

  let (data1, data2, data3) = await Promise.all3((
    one->responseToOption,
    two->responseToOption,
    three->responseToOption,
  ))

  let unmaintained = []

  let pkges =
    [data1, data2, data3]
    ->Array.filterMap(d =>
      switch d {
      | Some(d) => Some(parsePkgs(d))
      | None => None
      }
    )
    ->Array.flat
    ->Array.filter(pkg => {
      if packageAllowList->Array.includes(pkg.name) {
        true
      } else if pkg.name->String.includes("reason") {
        false
      } else if pkg.maintenanceScore < 0.3 {
        unmaintained->Array.push(pkg)
        false
      } else {
        true
      }
    })

  let index_data_dir = Node.Path.join2(Node.Process.cwd(), "./data")
  let urlResources =
    Node.Path.join2(index_data_dir, "packages_url_resources.json")
    ->Node.Fs.readFileSync
    ->JSON.parseOrThrow
    ->unsafeToUrlResource

  {
    "props": {
      packages: pkges,
      unmaintained,
      urlResources,
    },
  }
}
