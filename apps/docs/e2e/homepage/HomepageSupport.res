open Cypress

let _ = realEvents
forbidOnly(!isInteractive())

beforeEach(() => {
  run(() => automate({command: "Network.clearBrowserCache"}))->ignore
  let spies = ref([])
  wrap(spies)->as_("consoleSpies")->ignore
  onBeforeLoad(window => {
    let script = window.document->currentScript->Null.toOption
    let marker =
      script->Option.flatMap(script => script->getAttribute("data-cy-bootstrap")->Null.toOption)
    expect(marker, ~message="Cypress uses the stable bootstrap slot")->equal(Some(""))
    spies := [...spies.contents, spy(window.console)]
  })
})

afterEach(() => {
  alias("@consoleSpies")
  ->then(spies => spies.contents->Array.forEach(spy => expect(spy->callCount)->equal(0)))
  ->ignore
})
