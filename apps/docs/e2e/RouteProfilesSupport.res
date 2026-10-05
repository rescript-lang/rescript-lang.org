open Cypress

beforeEach(() => {
  let spies = ref([])
  wrap(spies)->as_("consoleSpies")->ignore
  wrap([])->as_("expectedConsoleErrors")->ignore
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
  ->then(spies => {
    let errors =
      spies.contents
      ->Array.flatMap(getCalls)
      ->Array.map(call => call.args->Array.get(0)->consoleArgumentString)
    alias("@expectedConsoleErrors")
    ->then(
      expected => {
        let unexpected =
          errors->Array.filter(
            error => !(expected->Array.some(pattern => pattern->RegExp.test(error))),
          )
        expect(
          unexpected->Array.length,
          ~message=`unexpected console errors: ${unexpected->Array.join("; ")}`,
        )->equal(0)
        expected->Array.forEach(
          pattern =>
            expect(
              errors->Array.some(error => pattern->RegExp.test(error)),
              ~message="expected console error occurred",
            )->equal(true),
        )
      },
    )
    ->ignore
  })
  ->ignore
})
