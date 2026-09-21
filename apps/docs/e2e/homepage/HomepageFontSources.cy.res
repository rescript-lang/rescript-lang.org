open Cypress
open HomepageHelpers

type fontFace = {
  family: string,
  weight: string,
  style_: string,
  source: string,
  display: string,
  unicodeRange: string,
}

let rec collectFontFaces = rules =>
  rules->Array.flatMap(rule => {
    if rule->ruleType === 5 {
      let style = rule->ruleStyle
      [
        {
          family: style->fontFamily->String.replaceAll("\"", ""),
          weight: style->fontWeight,
          style_: style->fontStyle,
          source: style->propertyValue("src"),
          display: style->propertyValue("font-display"),
          unicodeRange: style->propertyValue("unicode-range"),
        },
      ]
    } else {
      switch rule->nestedRules->Nullable.toOption {
      | Some(rules) => rules->rulesFrom->collectFontFaces
      | None => []
      }
    }
  })

let readFontFaces = () =>
  cyWindow()->thenMap(window => {
    window.document
    ->styleSheets
    ->styleSheetsFrom
    ->Array.flatMap(sheet => sheet->sheetRules->rulesFrom->collectFontFaces)
  })

let findFontFace = (faces, family, weight, ~style="normal") =>
  faces->Array.find(face =>
    face.family === family && face.weight === weight && face.style_ === style
  )

let requireFontFace = (face, message) => {
  expect(face->Option.isSome, ~message)->equal(true)
  face->Option.getOrThrow
}

it("homepage consumes its preloaded Inter faces without bypassing them for local fonts", () => {
  visit("/")
  containsIn("h1", headline)
  ->shouldCssProperty("font-family")
  ->andMatch(/^"Homepage Inter", Inter,/)
  ->ignore
  readFontFaces()
  ->then(faces => {
    [("400", "Regular"), ("600", "SemiBold"), ("700", "Bold")]->Array.forEach(
      ((weight, file)) => {
        let homepageFace =
          findFontFace(faces, "Homepage Inter", weight)->requireFontFace(`Homepage Inter ${weight}`)
        let sharedFace = findFontFace(faces, "Inter", weight)->requireFontFace(`Inter ${weight}`)
        expect(homepageFace.source)->match_(/^url\(/)
        expect(homepageFace.source)->include_(`/fonts/subset-Inter-${file}.woff2`)
        expect(homepageFace.source)->notInclude("local(")
        expect(homepageFace.display)->equal("swap")
        expect(homepageFace.unicodeRange)->equal(sharedFace.unicodeRange)
        expect(sharedFace.source)->match_(/^local\(/)
      },
    )
  })
  ->ignore
})

it("homepage preserves the existing Medium and Italic font faces", () => {
  visit("/")
  readFontFaces()
  ->then(faces => {
    [("500", "normal"), ("400", "italic")]->Array.forEach(
      ((weight, style_)) => {
        let homepageFace =
          findFontFace(faces, "Homepage Inter", weight, ~style=style_)->requireFontFace(
            `Homepage Inter ${weight} ${style_}`,
          )
        let sharedFace =
          findFontFace(faces, "Inter", weight, ~style=style_)->requireFontFace(
            `Inter ${weight} ${style_}`,
          )
        expect(homepageFace)->deepEqual({...sharedFace, family: "Homepage Inter"})
      },
    )
  })
  ->ignore
})

it("documentation keeps its local-first Inter family across homepage navigation", () => {
  visit("/")
  containsInRegex("a", /^Docs$/)->click->ignore
  containsInRegex("h1", /^ReScript$/)->shouldCssProperty("font-family")->andMatch(/^Inter,/)->ignore
  readFontFaces()
  ->then(faces => {
    let sharedFaces = faces->Array.filter(face => face.family === "Inter")
    expect(sharedFaces->Array.length)->equal(5)
    sharedFaces->Array.forEach(face => expect(face.source)->match_(/^local\(/))
  })
  ->ignore
  get(`a[aria-label="homepage"]`)->click->ignore
  containsIn("h1", headline)
  ->shouldCssProperty("font-family")
  ->andMatch(/^"Homepage Inter", Inter,/)
  ->ignore
  containsInRegex("a", /^Docs$/)->click->ignore
  containsInRegex("h1", /^ReScript$/)->shouldCssProperty("font-family")->andMatch(/^Inter,/)->ignore
})
