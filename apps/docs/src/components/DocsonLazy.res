module Internal = {
  let make = React.lazy_(() => import(Docson.make))
}

let fallback = <div id="docson-root" />

@react.component
let make = (~tag) => {
  let (isMounted, setMounted) = React.useState(_ => false)

  React.useEffect(() => {
    setMounted(_ => true)
    None
  }, [])

  // Docson mutates the DOM and depends on browser globals, so keep the first
  // client render identical to the prerendered HTML and load it after hydration.
  if isMounted {
    <React.Suspense fallback>
      <Internal tag />
    </React.Suspense>
  } else {
    fallback
  }
}
