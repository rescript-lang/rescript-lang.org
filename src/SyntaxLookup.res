module Category = {
  type t =
    | Decorators
    | Operators
    | LanguageConstructs
    | BuiltInFunctions
    | ExtensionPoints
    | SpecialValues
    | Other

  let toString = t =>
    switch t {
    | Decorators => "Decorators"
    | Operators => "Operators"
    | ExtensionPoints => "Extension Points"
    | BuiltInFunctions => "Built-In Functions"
    | LanguageConstructs => "Language Constructs"
    | SpecialValues => "Special Values"
    | Other => "Other"
    }

  let fromString = (s: string): t => {
    switch s {
    | "decorators" => Decorators
    | "operators" => Operators
    | "languageconstructs" => LanguageConstructs
    | "builtinfunctions" => BuiltInFunctions
    | "extensionpoints" => ExtensionPoints
    | "specialvalues" => SpecialValues
    | _ => Other
    }
  }

  @react.component
  let make = (~title, ~children) => {
    <div>
      <h3 className="font-sans font-medium text-gray-100 tracking-wide text-14 uppercase mb-2">
        {React.string(title)}
      </h3>
      <div className="flex flex-wrap"> children </div>
    </div>
  }
}

module Status = {
  type t =
    | Active
    | Deprecated

  let fromString = (s: string): t =>
    switch s {
    | "deprecated" => Deprecated
    | "active" | _ => Active
    }

  let compare = (a, b) =>
    switch (a, b) {
    | (Deprecated, Deprecated) | (Active, Active) => Ordering.equal
    | (Active, Deprecated) => Ordering.less
    | (Deprecated, Active) => Ordering.greater
    }
}

module Item = {
  // The data representing a syntax construct
  // handled in the widget
  type t = {
    id: string,
    keywords: array<string>,
    name: string,
    summary: string,
    category: Category.t,
    children: React.element,
    status: Status.t,
  }

  let compare = (a, b) =>
    switch Status.compare(a.status, b.status) {
    | 0. => String.compare(a.name, b.name)
    | x => x
    }
}

type itemInfo = {
  id: string,
  keywords: array<string>,
  name: string,
  summary: string,
  category: Category.t,
  status: Status.t,
}

let getAnchor = path => {
  switch String.split(path, "#") {
  | [_, anchor] => Some(anchor)
  | _ => None
  }
}

module Tag = {
  @react.component
  let make = (~deprecated: bool, ~text: string) => {
    <span
      className={`
       py-1 px-3 rounded text-16
      ${deprecated
          ? "hover:bg-gray-30 bg-gray-50 text-gray-80 line-through"
          : "hover:bg-fire hover:text-white bg-fire-5 text-fire"}`}>
      {React.string(text)}
    </span>
  }
}

module DetailBox = {
  @react.component
  let make = (~summary: string, ~children: React.element) => {
    let summaryEl = switch String.split(summary, "`") {
    | [] => React.null
    | [first, second, third] =>
      [
        React.string(first),
        <span className="text-fire"> {React.string(second)} </span>,
        React.string(third),
      ]
      ->Array.mapWithIndex((el, i) => {
        <span key={Int.toString(i)}> el </span>
      })
      ->React.array
    | more => Array.map(more, s => React.string(s))->React.array
    }

    <div>
      <div className="text-24 border-b border-gray-40 pb-4 mb-4 font-semibold"> summaryEl </div>
      <div className="mt-16"> children </div>
    </div>
  }
}

type state =
  | ShowAll
  | ShowFiltered(string, array<Item.t>) // (search, filteredItems)
  | ShowDetails(Item.t)

let scrollToTop = () => WebAPI.Window.scrollTo(window, ~options={left: 0.0, top: 0.0})

type props = {mdxSources: array<MdxRemote.output>}
type params = {slug: string}

let decode = (json: JSON.t) => {
  open JSON
  switch json {
  | Object(dict{
      "id": String(id),
      "keywords": Array(keywords),
      "name": String(name),
      "summary": String(summary),
      "category": String(category),
      "status": ?status,
    }) => {
      id,
      name,
      summary,
      category: Category.fromString(category),
      keywords: keywords->Array.filterMap(k =>
        switch k {
        | String(k) => Some(k)
        | _ => None
        }
      ),
      status: switch status {
      | Some(String(status)) => status->Status.fromString
      | _ => Status.Active
      },
    }
  | _ => throw(Failure(`Failed to decode SyntaxLookup. ${__LOC__}`))
  }
}

let default = (props: props) => {
  let {mdxSources} = props

  let allItems = mdxSources->Array.map(mdxSource => {
    let {id, keywords, category, summary, name, status} = decode(mdxSource.frontmatter)

    let children =
      <MdxRemote
        frontmatter={mdxSource.frontmatter}
        compiledSource={mdxSource.compiledSource}
        scope={mdxSource.scope}
        components={MarkdownComponents.default}
      />

    {Item.id, keywords, category, summary, name, status, children}
  })

  let fuseOpts = Fuse.Options.t(
    ~shouldSort=false,
    ~includeScore=true,
    ~threshold=0.2,
    ~location=0,
    ~distance=30,
    ~minMatchCharLength=1,
    ~keys=["keywords", "name"],
    (),
  )

  let fuse: Fuse.t<Item.t> = Fuse.make(allItems, fuseOpts)

  let router = Next.Router.useRouter()
  let (state, setState) = React.useState(_ => ShowAll)

  let findItemById = id => allItems->Array.find(item => item.id === id)

  let findItemByExactName = name => allItems->Array.find(item => item.name === name)

  let searchItems = value =>
    fuse
    ->Fuse.search(value)
    ->Array.map(m => {
      m["item"]
    })

  // This effect is responsible for updating the view state when the router anchor changes.
  // This effect is triggered when:
  // [A] The page first loads.
  // [B] The search box is cleared.
  // [C] The search box value exactly matches an item name.
  React.useEffect(() => {
    switch getAnchor(router.asPath) {
    | None => setState(_ => ShowAll)
    | Some(anchor) =>
      switch findItemById(anchor) {
      | None => setState(_ => ShowAll)
      | Some(item) => {
          setState(_ => ShowDetails(item))
          scrollToTop()
        }
      }
    }
    None
  }, [router])

  // onSearchValueChange() is called when:
  // [A] The search value changes.
  // [B] The search is cleared.
  // [C] One of the tags is selected.
  //
  // We then handle three cases:
  // [1] Search is empty - trigger a route change, and allow the EFFECT to update the view state.
  // [2] Search exactly matches an item - trigger a route change, and allow the EFFECT to update the view state.
  // [3] Search does not match an item - immediately update the view state to show filtered items.
  let onSearchValueChange = value => {
    switch value {
    | "" => router->Next.Router.push("/syntax-lookup")
    | value =>
      switch findItemByExactName(value) {
      | None => {
          let filtered = searchItems(value)
          setState(_ => ShowFiltered(value, filtered))
        }

      | Some(item) => router->Next.Router.push("/syntax-lookup#" ++ item.id)
      }
    }
  }

  let details = switch state {
  | ShowFiltered(_, _)
  | ShowAll => React.null
  | ShowDetails(item) =>
    <div className="mb-16">
      <DetailBox summary={item.summary}> item.children </DetailBox>
    </div>
  }

  /*
    Order all items in tag groups
 */
  let categories = {
    let initial = [
      Category.Decorators,
      Operators,
      LanguageConstructs,
      BuiltInFunctions,
      ExtensionPoints,
      SpecialValues,
      Other,
    ]->Array.map(cat => {
      (cat->Category.toString, [])
    })

    let items = switch state {
    | ShowAll => allItems
    | ShowDetails(_) => []
    | ShowFiltered(_, items) => items
    }

    Array.reduce(items, Dict.fromArray(initial), (acc, item) => {
      let key = item.category->Category.toString
      Dict.get(acc, key)->Option.mapOr(acc, items => {
        Array.push(items, item)->ignore
        Dict.set(acc, key, items)
        acc
      })
    })
    ->Dict.toArray
    ->Array.reduce([], (acc, entry) => {
      let (title, items) = entry
      if Array.length(items) === 0 {
        acc
      } else {
        let children =
          items
          ->Array.toSorted(Item.compare)
          ->Array.map(item => {
            let onMouseDown = evt => {
              ReactEvent.Mouse.preventDefault(evt)
              onSearchValueChange(item.name)
            }
            <span className="mr-2 mb-2 cursor-pointer" onMouseDown key=item.name>
              <Tag text={item.name} deprecated={item.status == Deprecated} />
            </span>
          })
        let el =
          <div key=title className="first:mt-0 mt-12">
            <Category title> {React.array(children)} </Category>
          </div>
        Array.push(acc, el)->ignore
        acc
      }
    })
  }

  let (searchValue, completionItems) = switch state {
  | ShowFiltered(search, items) => (search, items)
  | ShowAll => ("", allItems)
  | ShowDetails(item) => (item.name, [item])
  }

  let onSearchClear = () => {
    onSearchValueChange("")
  }

  let (isOverlayOpen, setOverlayOpen) = React.useState(() => false)
  let title = "Syntax Lookup | ReScript Documentation"

  let content =
    <div>
      <div className="flex flex-col items-center">
        <div className="text-center max-w-84">
          <Markdown.H1> {React.string("Syntax Lookup")} </Markdown.H1>
          <div className="mb-8 text-gray-60-tr text-14">
            {React.string("Enter some language construct you want to know more about.")}
          </div>
        </div>
        <div className="w-full max-w-136">
          <SearchBox
            placeholder="Enter keywords or syntax..."
            completionValues={Array.map(completionItems, item => item.name)}
            value=searchValue
            onClear=onSearchClear
            onValueChange=onSearchValueChange
          />
        </div>
      </div>
      <div className="mt-10">
        {details}
        {React.array(categories)}
      </div>
    </div>

  <>
    <Meta
      siteName="ReScript Syntax Lookup"
      title
      description="Discover ReScript syntax constructs with our lookup tool"
    />
    <div className="mt-4 xs:mt-16">
      <div className="text-gray-80">
        <Navigation isOverlayOpen setOverlayOpen />
        <div className="flex xs:justify-center overflow-hidden pb-48">
          <main className="mt-24 min-w-320 lg:align-center w-full px-4 md:px-8 max-w-1280">
            <MdxProvider components=MarkdownComponents.default>
              <div className="flex justify-center">
                <div className="max-w-740 w-full"> content </div>
              </div>
            </MdxProvider>
          </main>
        </div>
        <Footer />
      </div>
    </div>
  </>
}

let getStaticProps: Next.GetStaticProps.t<props, params> = async _ctx => {
  let dir = Node.Path.resolve("misc_docs", "syntax")

  let allFiles = Node.Fs.readdirSync(dir)->Array.map(async file => {
    let fullPath = Node.Path.join2(dir, file)
    let source = fullPath->Node.Fs.readFileSync
    await MdxRemote.serialize(
      source,
      {parseFrontmatter: true, mdxOptions: MdxRemote.defaultMdxOptions},
    )
  })

  let mdxSources = await Promise.all(allFiles)

  {"props": {mdxSources: mdxSources}}
}
