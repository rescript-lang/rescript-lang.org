module Docgen = RescriptTools.Docgen

type rec node = {
  name: string,
  path: array<string>,
  children: array<node>,
}

type field = {
  name: string,
  docstrings: array<string>,
  signature: string,
  optional: bool,
  deprecated: Null.t<string>,
}
type constructor = {
  name: string,
  docstrings: array<string>,
  signature: string,
  deprecated: Null.t<string>,
}

type detail =
  | Record({items: array<field>})
  | Variant({items: array<constructor>})

type item =
  | Value({
      id: string,
      docstrings: array<string>,
      signature: string,
      name: string,
      deprecated: Null.t<string>,
    })
  | Type({
      id: string,
      docstrings: array<string>,
      signature: string,
      name: string,
      deprecated: Null.t<string>,
      detail: Null.t<detail>,
    })

module RightSidebar = {
  @react.component
  let make = (~items: array<item>) => {
    items
    ->Array.map(item => {
      switch item {
      | Value({name, deprecated}) as kind | Type({name, deprecated}) as kind =>
        let (icon, textColor, bgColor, href) = switch kind {
        | Type(_) => ("t", "text-fire-30", "bg-fire-5", `#type-${name}`)
        | Value(_) => ("v", "text-sky-30", "bg-sky-5", `#value-${name}`)
        }
        let deprecatedIcon = switch deprecated->Null.toOption {
        | Some(_) =>
          <div
            className={`bg-orange-100 min-w-[20px] min-h-[20px] w-5 h-5 mr-3 flex justify-center items-center rounded-xl ml-auto`}>
            <span className={"text-[10px] text-orange-400"}> {"D"->React.string} </span>
          </div>->Some
        | None => None
        }
        let title = `${Option.isSome(deprecatedIcon) ? "Deprecated " : ""}` ++ name
        let result =
          <li className="my-3" key={href}>
            <a
              title
              className="flex items-center w-full font-normal text-14 text-gray-40 leading-tight hover:text-gray-80"
              href>
              <div
                className={`${bgColor} min-w-[20px] min-h-[20px] w-5 h-5 mr-3 flex justify-center items-center rounded-xl`}>
                <span className={"text-[10px] font-normal " ++ textColor}>
                  {icon->React.string}
                </span>
              </div>
              <span className={"truncate"}> {React.string(name)} </span>
              {switch deprecatedIcon {
              | Some(icon) => icon
              | None => React.null
              }}
            </a>
          </li>
        result
      }
    })
    ->React.array
  }
}

module SidebarTree = {
  @react.component
  let make = (~isOpen: bool, ~toggle: unit => unit, ~node: node, ~items: array<item>) => {
    let router = Next.Router.useRouter()
    let url = router.route->Url.parse
    let version = url->Url.getVersionString

    let moduleRoute =
      Webapi.URL.make("file://" ++ router.asPath).pathname
      ->String.replace(`/docs/manual/${version}/api/`, "")
      ->String.split("/")

    let summaryClassName = "truncate py-1 md:h-auto tracking-tight text-gray-60 font-medium text-14 rounded-sm hover:bg-gray-20 hover:-ml-2 hover:py-1 hover:pl-2 "
    let classNameActive = " bg-fire-5 text-red-500 -ml-2 pl-2 font-medium hover:bg-fire-70"

    let subMenu = switch items->Array.length > 0 {
    | true =>
      <div className={"xl:hidden ml-5"}>
        <ul className={"list-none py-0.5"}>
          <RightSidebar items />
        </ul>
      </div>
    | false => React.null
    }

    let rec renderNode = node => {
      let isCurrentRoute = Array.join(moduleRoute, "/") === Array.join(node.path, "/")

      let classNameActive = isCurrentRoute ? classNameActive : ""

      let hasChildren = node.children->Array.length > 0
      let href = node.path->Array.join("/")

      let tocModule = isCurrentRoute ? subMenu : React.null

      switch hasChildren {
      | true =>
        let open_ =
          href ===
            moduleRoute
            ->Array.slice(~start=0, ~end=Array.length(moduleRoute) - 1)
            ->Array.join("/")

        <details key={href} open_>
          <summary className={summaryClassName ++ classNameActive}>
            <Next.Link className={"inline-block w-10/12"} href>
              {node.name->React.string}
            </Next.Link>
          </summary>
          tocModule
          {if hasChildren {
            <ul className={"ml-5"}>
              {node.children
              ->Array.map(renderNode)
              ->React.array}
            </ul>
          } else {
            React.null
          }}
        </details>
      | false =>
        <li className={"list-none mt-1 leading-4"} key={href}>
          <summary className={summaryClassName ++ classNameActive}>
            <Next.Link className={"block"} href> {node.name->React.string} </Next.Link>
          </summary>
          tocModule
        </li>
      }
    }

    let url =
      router.asPath
      ->Url.parse
      ->Some

    let preludeSection =
      <div className="flex justify-between text-fire font-medium items-baseline">
        {switch url {
        | Some(url) =>
          let onChange = evt => {
            open Url
            ReactEvent.Form.preventDefault(evt)
            let version = (evt->ReactEvent.Form.target)["value"]
            let url = Url.parse(router.asPath)
            switch url.pagepath[1] {
            | Some("core") | Some("stdlib") =>
              if version < "v12.0.0" {
                url.pagepath[1] = "core"
              } else {
                url.pagepath[1] = "stdlib"
              }
            | _ => ()
            }

            let targetUrl =
              "/" ++
              (Array.join(url.base, "/") ++
              ("/" ++ (version ++ ("/" ++ Array.join(url.pagepath, "/")))))
            router->Next.Router.push(targetUrl)
          }
          let version = url->Url.getVersionString

          <VersionSelect
            onChange
            version
            availableVersions=Constants.stdlibVersions
            nextVersion=?Constants.nextVersion
          />

        | None => React.null
        }}
      </div>

    <div
      className={(
        isOpen ? "fixed w-full left-0 h-full z-20 min-w-320" : "hidden "
      ) ++ " md:block md:w-48 md:-ml-4 lg:w-1/5 md:h-auto md:relative overflow-y-visible bg-white"}>
      <aside
        id="sidebar-content"
        className="relative top-0 px-4 w-full block md:top-[7rem] md:pt-10 md:sticky border-r border-gray-20 overflow-y-auto pb-24 h-[calc(100vh-7rem)]">
        <div className="flex justify-between">
          <div className="w-3/4 md:w-full"> React.null </div>
          <button
            onClick={evt => {
              ReactEvent.Mouse.preventDefault(evt)
              toggle()
            }}
            className="md:hidden h-16">
            <Icon.Close />
          </button>
        </div>
        preludeSection
        <div className="my-10">
          <div className="hl-overline block text-gray-80 mt-5 mb-2">
            {"Overview"->React.string}
          </div>
          <Next.Link
            className={"block " ++
            summaryClassName ++ (moduleRoute->Array.length == 1 ? classNameActive : "")}
            href={node.path->Array.join("/")}>
            {node.name->React.string}
          </Next.Link>
          {moduleRoute->Array.length === 1 ? subMenu : React.null}
        </div>
        <div className="hl-overline text-gray-80 mt-5 mb-2"> {"submodules"->React.string} </div>
        {node.children
        ->Array.toSorted((v1, v2) => String.compare(v1.name, v2.name))
        ->Array.map(renderNode)
        ->React.array}
      </aside>
    </div>
  }
}

type module_ = {
  id: string,
  docstrings: array<string>,
  deprecated: Null.t<string>,
  name: string,
  items: array<item>,
}

type api = {
  module_: module_,
  toctree: node,
}

type params = {slug: array<string>}
type props = result<api, string>

module MarkdownStylize = {
  @react.component
  let make = (~content, ~rehypePlugins) => {
    let components = {
      ...MarkdownComponents.default,
      h2: MarkdownComponents.default.h3->Obj.magic,
    }
    <ReactMarkdown components={components} ?rehypePlugins> content </ReactMarkdown>
  }
}

module DeprecatedMessage = {
  @react.component
  let make = (~deprecated) => {
    switch deprecated->Null.toOption {
    | Some(content) =>
      <Markdown.Warn>
        <h4 className={"hl-4 mb-2"}> {"Deprecated"->React.string} </h4>
        <MarkdownStylize content rehypePlugins=None />
      </Markdown.Warn>
    | None => React.null
    }
  }
}

module DocstringsStylize = {
  @react.component
  let make = (~docstrings, ~slugPrefix) => {
    let rehypePlugins =
      [Rehype.WithOptions([Plugin(Rehype.slug), SlugOption({prefix: slugPrefix ++ "-"})])]->Some

    let content = switch docstrings->Array.length > 1 {
    | true => docstrings->Array.sliceToEnd(~start=1)
    | false => docstrings
    }->Array.join("\n")

    <div className={"mt-3"}>
      <MarkdownStylize content rehypePlugins />
    </div>
  }
}

let default = (props: props) => {
  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)
  let toggleSidebar = () => setSidebarOpen(prev => !prev)
  let router = Next.Router.useRouter()

  let title = switch props {
  | Ok({module_: {id}}) => id
  | _ => "API"
  }

  let children = {
    open Markdown
    switch props {
    | Ok({module_: {id, name, docstrings, items}}) =>
      let valuesAndType = items->Array.map(item => {
        switch item {
        | Value({name, signature, docstrings, deprecated}) =>
          let code = String.replaceRegExp(signature, /\\n/g, "\n")
          let slugPrefix = "value-" ++ name
          <React.Fragment key={slugPrefix}>
            <H2 id=slugPrefix> {name->React.string} </H2>
            <DeprecatedMessage deprecated />
            <CodeExample code lang="rescript" />
            <DocstringsStylize docstrings slugPrefix />
          </React.Fragment>
        | Type({name, signature, docstrings, deprecated}) =>
          let code = String.replaceRegExp(signature, /\\n/g, "\n")
          let slugPrefix = "type-" ++ name
          <React.Fragment key={slugPrefix}>
            <H2 id=slugPrefix> {name->React.string} </H2>
            <DeprecatedMessage deprecated />
            <CodeExample code lang="rescript" />
            <DocstringsStylize docstrings slugPrefix />
          </React.Fragment>
        }
      })

      <>
        <H1> {name->React.string} </H1>
        <DocstringsStylize docstrings slugPrefix=id />
        {valuesAndType->React.array}
      </>
    | _ => React.null
    }
  }

  let rightSidebar = switch props {
  | Ok({module_: {items}}) if Array.length(items) > 0 =>
    <div className="hidden xl:block lg:w-1/5 md:h-auto md:relative overflow-y-visible bg-white">
      <aside
        className="relative top-0 pl-4 w-full block md:top-[7rem] md:pt-4 md:sticky border-l border-gray-20 overflow-y-auto pb-24 h-[calc(100vh-7rem)]">
        <div className="hl-overline block text-gray-80 mt-16 mb-2">
          {"Types and values"->React.string}
        </div>
        <ul>
          <RightSidebar items />
        </ul>
      </aside>
    </div>
  | _ => React.null
  }

  let version = Url.parse(router.asPath)->Url.getVersionString

  let sidebar = switch props {
  | Ok({toctree, module_: {items}}) =>
    <SidebarTree isOpen=isSidebarOpen toggle=toggleSidebar node={toctree} items />
  | Error(_) => React.null
  }

  let prefix = {
    {Url.name: "API", href: "/docs/manual/" ++ (version ++ "/api")}
  }

  let breadcrumbs = ApiLayout.makeBreadcrumbs(~prefix, router.asPath)

  <SidebarLayout
    breadcrumbs
    metaTitle={title ++ " | ReScript API"}
    theme=#Reason
    components=ApiMarkdown.default
    sidebarState=(isSidebarOpen, setSidebarOpen)
    sidebar
    rightSidebar>
    children
  </SidebarLayout>
}

module Data = {
  type t = {
    mainModule: Dict.t<JSON.t>,
    tree: Dict.t<JSON.t>,
  }

  let dir = Node.Path.resolve("data", "api")

  let getVersion = (~version: string, ~moduleName: string) => {
    open Node

    let pathModule = Path.join([dir, version, `${moduleName}.json`])

    let moduleContent = Fs.readFileSync(pathModule)->JSON.parseOrThrow

    let content = switch moduleContent {
    | Object(dict) => dict->Some
    | _ => None
    }

    let toctree = switch Path.join([dir, version, "toc_tree.json"])
    ->Fs.readFileSync
    ->JSON.parseOrThrow {
    | Object(dict) => dict->Some
    | _ => None
    }

    switch (content, toctree) {
    | (Some(content), Some(toctree)) => Some({mainModule: content, tree: toctree})
    | _ => None
    }
  }
}

let processStaticProps = (~slug: array<string>, ~version: string) => {
  let moduleName = slug->Belt.Array.getExn(0)
  let content = Data.getVersion(~version, ~moduleName)

  let modulePath = slug->Array.join("/")

  switch content {
  | Some({mainModule, tree}) =>
    switch mainModule->Dict.get(modulePath) {
    | Some(json) =>
      let {items, docstrings, deprecated, name} = Docgen.decodeFromJson(json)
      let id = switch json {
      | Object(dict) =>
        switch Dict.get(dict, "id") {
        | Some(String(s)) => s
        | _ => ""
        }
      | _ => ""
      }

      let items = items->Array.map(item =>
        switch item {
        | Docgen.Value({id, docstrings, signature, name, ?deprecated}) =>
          Value({
            id,
            docstrings,
            signature,
            name,
            deprecated: deprecated->Null.fromOption,
          })
        | Type({id, docstrings, signature, name, ?deprecated, ?detail}) =>
          let detail = switch detail {
          | Some(kind) =>
            switch kind {
            | Docgen.Record({items}) =>
              let items = items->Array.map(({
                name,
                docstrings,
                signature,
                optional,
                ?deprecated,
              }) => {
                {
                  name,
                  docstrings,
                  signature,
                  optional,
                  deprecated: deprecated->Null.fromOption,
                }
              })
              Record({items: items})->Null.make
            | Variant({items}) =>
              let items = items->Array.map(({name, docstrings, signature, ?deprecated}) => {
                {
                  name,
                  docstrings,
                  signature,
                  deprecated: deprecated->Null.fromOption,
                }
              })

              Variant({items: items})->Null.make
            | Signature(_) => Null.null
            }
          | None => Null.null
          }
          Type({
            id,
            docstrings,
            signature,
            name,
            deprecated: deprecated->Null.fromOption,
            detail,
          })
        | _ => assert(false)
        }
      )
      let module_ = {
        id,
        name,
        docstrings,
        deprecated: deprecated->Null.fromOption,
        items,
      }

      let toctree = tree->Dict.get(moduleName)

      switch toctree {
      | Some(toctree) => Ok({module_, toctree: (Obj.magic(toctree): node)})
      | None => Error(`Failed to find toctree to ${modulePath}`)
      }

    | None => Error(`Failed to get key for ${modulePath}`)
    }
  | None => Error(`Failed to get API Data for version ${version} and module ${moduleName}`)
  }
}

let getStaticPropsByVersion = async (ctx: {"params": params, "version": string}) => {
  let params = ctx["params"]
  let version = ctx["version"]

  let slug = params.slug

  let result = processStaticProps(~slug, ~version)

  {"props": result}
}

let getStaticPathsByVersion = async (~version: string) => {
  open Node

  let pathDir = Path.join([Data.dir, version])

  let slugs =
    pathDir
    ->Fs.readdirSync
    ->Array.reduce([], (acc, file) => {
      switch file == "toc_tree.json" {
      | true => acc
      | false =>
        let paths = switch Path.join2(pathDir, file)
        ->Fs.readFileSync
        ->JSON.parseOrThrow {
        | Object(dict) =>
          dict
          ->Dict.keysToArray
          ->Array.map(modPath => modPath->String.split("/"))
        | _ => acc
        }
        Array.concat(acc, paths)
      }
    })

  let paths = slugs->Array.map(slug =>
    {
      "params": {
        "slug": slug,
      },
    }
  )

  {"paths": paths, "fallback": false}
}
