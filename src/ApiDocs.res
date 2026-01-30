module Docgen = RescriptTools.Docgen

let apiDocsRootPath = "/docs/manual/api"

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
  let make = (~items: array<item>, ~onClick) => {
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
            className={`bg-orange-100 min-w-[20px] min-h-[20px] w-5 h-5 mr-3 flex justify-center items-center rounded-xl ml-auto`}
          >
            <span className={"text-[10px] text-orange-400"}> {"D"->React.string} </span>
          </div>->Some
        | None => None
        }
        let title = `${Option.isSome(deprecatedIcon) ? "Deprecated " : ""}` ++ name
        let result =
          <li className="my-3" key={href}>
            <ReactRouter.Link.String
              title
              className="flex items-center w-full font-normal text-14 text-gray-40 leading-tight hover:text-gray-80"
              to=href
              onClick={_ => onClick()}
            >
              <div
                className={`${bgColor} min-w-[20px] min-h-[20px] w-5 h-5 mr-3 flex justify-center items-center rounded-xl`}
              >
                <span className={"text-[10px] font-normal " ++ textColor}>
                  {icon->React.string}
                </span>
              </div>
              <span className={"truncate"}> {React.string(name)} </span>
              {switch deprecatedIcon {
              | Some(icon) => icon
              | None => React.null
              }}
            </ReactRouter.Link.String>
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
    open ReactRouter

    let location = useLocation()

    let moduleRoute = `${apiDocsRootPath}/${(location.pathname :> string)
      ->String.replace(`/docs/manual/api/`, "")
      ->String.split("/")
      ->Array.get(0)
      ->Option.getOr("stdlib")}`

    let isCurrentlyAtRoot = (location.pathname :> string) == moduleRoute

    let summaryClassName = "truncate py-1 md:h-auto tracking-tight text-gray-60 font-medium text-14 rounded-sm hover:bg-gray-20 hover:-ml-2 hover:py-1 hover:pl-2 "
    let classNameActive = " bg-fire-5 text-red-500 -ml-2 pl-2 font-medium hover:bg-fire-70"

    let subMenu = switch items->Array.length > 0 {
    | true =>
      <div className={"xl:hidden ml-5"} dataTestId={`submenu-${node.name}`}>
        <ul className={"list-none py-0.5"}>
          <RightSidebar items onClick=toggle />
        </ul>
      </div>
    | false => React.null
    }

    let rec renderNode = node => {
      // this value is the relative path to this module, e.g. "/array" or "/int"
      let relativePath = node.path->Array.join("/")->Url.normalizePath

      // This is the full path to this module, e.g. "/docs/manual/api/stdlib/array" or "/docs/manual/api/stdlib/int"
      let fullPath = `${moduleRoute}/${relativePath}`->Url.normalizePath

      let isCurrentRoute = fullPath == (location.pathname :> string)

      let classNameActive = isCurrentRoute ? classNameActive : ""

      let hasChildren = node.children->Array.length > 0

      let tocModule = isCurrentRoute ? subMenu : React.null

      switch hasChildren {
      | true =>
        let open_ = (location.pathname :> string)->String.includes(fullPath)

        <details
          key={node.name}
          open_
          dataTestId={`has-children-${node.name->String.toLowerCase}-${isCurrentRoute->Bool.toString}`}
        >
          <summary
            className={summaryClassName ++ classNameActive}
            dataTestId={`${node.name}-is-current-${isCurrentRoute->Bool.toString}`}
          >
            <Link.String className={"inline-block w-10/12"} to={fullPath}>
              {node.name->React.string}
            </Link.String>
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
        <li
          className="list-none mt-1 leading-4" key=node.name dataTestId={`no-children-${node.name}`}
        >
          <summary className={summaryClassName ++ classNameActive}>
            <Link.String className={"block"} to=fullPath> {node.name->React.string} </Link.String>
          </summary>
          tocModule
        </li>
      }
    }

    let preludeSection =
      <div className="flex justify-between text-fire font-medium items-baseline">
        <VersionSelect />
      </div>

    <div
      id="sidebar"
      className={(
        isOpen ? "fixed w-full left-0 h-full z-20 min-w-320" : "hidden "
      ) ++ " md:block md:w-48 md:-ml-4 lg:w-1/5 h-auto md:relative overflow-y-visible bg-white mt-16 md:mt-0"}
    >
      <aside
        id="sidebar-content-api-docs"
        className="w-80 h-full relative top-12 px-4 w-full block md:top-28 md:sticky border-r border-gray-20 overflow-y-auto pb-24 max-h-[calc(100vh-7rem)]"
      >
        <div className="flex justify-between items-center">
          {preludeSection}
          <button
            onClick={evt => {
              ReactEvent.Mouse.preventDefault(evt)
              toggle()
            }}
            className="md:hidden h-auto"
          >
            <Icon.Close />
          </button>
        </div>

        <div className="my-10">
          <div className="hl-overline block text-gray-80 mt-5 mb-2" dataTestId="overview">
            {"Overview"->React.string}
          </div>
          <Link.String
            className={"block " ++ summaryClassName ++ (isCurrentlyAtRoot ? classNameActive : "")}
            to={moduleRoute}
          >
            {node.name->React.string}
          </Link.String>
          {isCurrentlyAtRoot ? subMenu : React.null}
        </div>
        <div className="hl-overline text-gray-80 mt-5 mb-2"> {"submodules"->React.string} </div>
        {node.children
        ->Array.toSorted((v1, v2) => String.compare(v1.name, v2.name))
        ->Array.filter(child => child.name !== node.name)
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
    | true => docstrings->Array.slice(~start=1)
    | false => docstrings
    }->Array.join("\n")

    <div className={"mt-3"}>
      <MarkdownStylize content rehypePlugins />
    </div>
  }
}

let make = (props: props) => {
  let (_, setScrollLock) = ScrollLockContext.useScrollLock()
  let isMobile = Hooks.useIsMobile()
  let (isSidebarOpen, setSidebarOpen) = React.useState(_ => false)

  React.useEffect(() => {
    setSidebarOpen(_ => !isMobile)
    None
  }, [isMobile])

  let toggleSidebar = () => {
    let nextSidebarOpen = !(isSidebarOpen && isMobile)
    setSidebarOpen(_ => nextSidebarOpen)
    setScrollLock(_ => nextSidebarOpen && isMobile)
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

  // This is the sidebar on the right side of the page for desktops showing types and values
  let rightSidebar = switch props {
  | Ok({module_: {items}}) if Array.length(items) > 0 =>
    <div className="hidden xl:block lg:w-1/5 md:h-auto md:relative overflow-y-visible bg-white">
      <aside
        className="relative pl-4 w-full block md:top-28 md:pt-4 md:sticky border-l border-gray-20 overflow-y-auto pb-24 h-[calc(100vh-7rem)]"
      >
        <div className="hl-overline block text-gray-80 mt-16 mb-2">
          {"Types and values"->React.string}
        </div>
        <ul>
          <RightSidebar items onClick=toggleSidebar />
        </ul>
      </aside>
    </div>
  | _ => React.null
  }

  // This is the inline sidebar on the left for mobile and tablet
  let sidebar = switch props {
  | Ok({toctree, module_: {items}}) =>
    <SidebarTree isOpen=isSidebarOpen toggle=toggleSidebar node={toctree} items />
  | Error(_) => {
      Console.error("Error loading API data")
      React.null
    }
  }

  let prefix = {Url.name: "API", href: "/docs/manual/api"}

  let {pathname: route} = ReactRouter.useLocation()

  let breadcrumbs = ApiLayout.makeBreadcrumbs(~prefix, route)

  <SidebarLayout
    breadcrumbs={list{{Url.name: "Docs", href: "/docs/manual/api"}, ...breadcrumbs}}
    theme=#Reason
    sidebarState=(isSidebarOpen, setSidebarOpen)
    sidebar
    rightSidebar
  >
    children
  </SidebarLayout>
}

module Data = {
  type t = {
    mainModule: Dict.t<JSON.t>,
    tree: Dict.t<JSON.t>,
  }

  let dir = try {
    Node.Path.resolve("data", "api")
  } catch {
  | _ => ""
  }

  let getVersion = (~moduleName: string) => {
    open Node

    let moduleContent =
      Fs.readFileSync(`markdown-pages/docs/api/${moduleName}.json`)->JSON.parseOrThrow

    let content = switch moduleContent {
    | Object(dict) => dict->Some
    | _ => None
    }

    switch content {
    | Some(content) => Some({mainModule: content, tree: Dict.make()})
    | _ => None
    }
  }
}

let processStaticProps = (~slug: array<string>) => {
  let moduleName = slug->Belt.Array.getExn(0)
  let modulePath = slug->Array.join("/")

  let content =
    // TODO post RR7: rename this to getByModuleName
    Data.getVersion(~moduleName)
    ->Option.map(data => data.mainModule)
    ->Option.flatMap(Dict.get(_, modulePath))

  let _content = content

  switch content {
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
            let items = items->Array.map(({name, docstrings, signature, optional, ?deprecated}) => {
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

    Ok({module_, toctree: Obj.magic({name: "root", path: [], children: []})})

  | None => Error(`Failed to get API Data for module ${moduleName}`)
  }
}

let getStaticProps = async slug => {
  let result = processStaticProps(~slug)

  {"props": result}
}
