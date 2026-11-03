open ScriptTest

type dom = {window: WebAPI.Window.t}
type clipboard = {writeText: string => promise<unit>}
type navigator = {clipboard?: clipboard}
type mockWindow = {document: WebAPI.DOM.document, navigator: navigator}
@module("jsdom") @new external makeDom: string => dom = "JSDOM"
@module("vitest") @scope("vi") external stubGlobal: (string, 'a) => unit = "stubGlobal"
@module("vitest") @scope("vi") external unstubGlobals: unit => unit = "unstubAllGlobals"
@send external close: WebAPI.Window.t => unit = "close"
@set external setCopyCommand: (WebAPI.DOM.document, string => bool) => unit = "execCommand"
@get external textareaValue: WebAPI.Element.t => string = "value"

let setup = (~writeNative=?) => {
  let dom = makeDom("<p>Selected text</p><button>Original focus</button>")
  let document = dom.window->WebAPI.Window.document
  let navigator = {clipboard: ?(writeNative->Option.map(writeText => {writeText: writeText}))}
  stubGlobal("window", {document, navigator})
  onTestFinished(async () => {
    unstubGlobals()
    close(dom.window)
  })
  document
}

let textareaCount = document => (document->WebAPI.Document.querySelectorAll("textarea")).length

test("clipboard prefers the native API without creating a fallback textarea", async () => {
  let copied = ref("")
  let document = setup(~writeNative=async text => copied := text)
  setCopyCommand(document, _ => {
    throw(Failure("Fallback should not run"))
  })
  expect(await Clipboard.writeText("let answer = 42"))->toStrictEqual(Ok())
  expect(copied.contents)->toBe("let answer = 42")
  expect(textareaCount(document))->toBe(0)
})

test("missing Clipboard API falls back and restores focus and selected text", async () => {
  let document = setup()
  let button = document->WebAPI.Document.querySelector("button")->Null.getOrThrow
  Clipboard.focusElement(button)
  let paragraph = document->WebAPI.Document.querySelector("p")->Null.getOrThrow
  let selection = document->WebAPI.Document.getSelection->Null.getOrThrow
  let range = document->WebAPI.Document.createRange
  range->WebAPI.Range.selectNodeContents(paragraph->WebAPI.Element.asNode)
  selection->WebAPI.Selection.removeAllRanges
  selection->WebAPI.Selection.addRange(range)
  expect(String.make(selection))->toBe("Selected text")

  let copied = ref("")
  setCopyCommand(document, command => {
    expect(command)->toBe("copy")
    let textarea = document->WebAPI.Document.querySelector("textarea")->Null.getOrThrow
    copied := textarea->textareaValue
    true
  })

  expect(await Clipboard.writeText("let answer = 42"))->toStrictEqual(Ok())
  expect(copied.contents)->toBe("let answer = 42")
  expect(document->WebDocument.activeElement)->toBe(Null.make(button))
  expect(String.make(selection))->toBe("Selected text")
  expect(textareaCount(document))->toBe(0)
})

test("a rejected native clipboard write tries the selection fallback", async () => {
  let document = setup(~writeNative=async _ => throw(Failure("Permission denied")))
  let commands = ref([])
  setCopyCommand(document, command => {
    commands.contents->Array.push(command)
    true
  })
  expect(await Clipboard.writeText("share URL"))->toStrictEqual(Ok())
  expect(commands.contents)->toStrictEqual(["copy"])
  expect(textareaCount(document))->toBe(0)
})

test("failed fallback commands report failure and remove their temporary textarea", async () => {
  let document = setup()
  setCopyCommand(document, _ => false)
  expect(await Clipboard.writeText("code"))->toStrictEqual(Error(Clipboard.WriteFailed))
  expect(textareaCount(document))->toBe(0)

  setCopyCommand(document, _ => throw(Failure("Copy unavailable")))
  expect(await Clipboard.writeText("code"))->toStrictEqual(Error(Clipboard.WriteFailed))
  expect(textareaCount(document))->toBe(0)
})
