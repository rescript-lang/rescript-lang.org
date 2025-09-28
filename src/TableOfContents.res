type entry = {
  header: string,
  href: string,
}

type t = {
  title: string,
  entries: array<entry>,
}

module Context = {
  let default: t = {
    title: "",
    entries: [],
  }

  type c = {
    toc: option<t>,
    addEntry: (string, string) => unit,
  }

  let context = React.createContext({toc: Some({title: "", entries: []}), addEntry: (_, _) => ()})

  module Provider = {
    let make = React.Context.provider(context)
  }

  let useTocContext = () => React.useContext(context)

  let emptyEntries: array<entry> = []

  @jsx.component
  let make = (~children, ~value: t) => {
    let (entries, setEntries) = React.useState(_ => emptyEntries)

    let addEntry = (header, href) => {
      setEntries(prev => prev->Array.concat([{header, href}]))
    }

    <Provider value={{toc: Some({title: value.title, entries}), addEntry}}> {children} </Provider>
  }
}
