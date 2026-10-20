open Vitest

test(
  "homepage example loader produces only serializable highlighted code and its URL",
  async () => {
    let data = LandingPagePlaygroundLoader.build()
    let serialized = data->JSON.stringifyAny->Option.getOrThrow
    let decoded = JSON.parseOrThrow(serialized)
    let expected = JSON.Object(
      Dict.fromArray([
        ("rescriptHtml", JSON.String(data.rescriptHtml)),
        ("javascriptHtml", JSON.String(data.javascriptHtml)),
        ("playgroundHref", JSON.String(data.playgroundHref)),
      ]),
    )

    expect(decoded)->toEqual(expected)
    expect(data.rescriptHtml->String.includes("<span"))->toBe(true)
    expect(data.javascriptHtml->String.includes("<span"))->toBe(true)
    let {pathname, searchParams} = WebAPI.URL.make(
      ~url=data.playgroundHref,
      ~base="https://rescript-lang.org",
    )
    let code = searchParams->WebAPI.URLSearchParams.get("code")

    expect(pathname)->toBe("/try")
    expect(LzString.lzString.decompressFromEncodedURIComponent(code))->toBe(
      LandingPageFixture.expectedExample,
    )
  },
)
