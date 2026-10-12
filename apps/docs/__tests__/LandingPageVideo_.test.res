open Vitest

let attribute = (selector, name) =>
  document
  ->WebAPI.Document.querySelector(selector)
  ->Null.toOption
  ->Option.flatMap(element => element->WebAPI.Element.getAttribute(name)->Null.toOption)

test(
  "homepage videos reserve dimensions and defer media loading while retaining controls",
  async () => {
    let _screen = await render(
      <LandingPageVideo
        poster="/lp/fast-build-preview.avif"
        src="https://assets-17077.kxcdn.com/videos/fast-build-3.mp4"
      />,
    )
    expect(attribute("video", "preload"))->toEqual(Some("none"))
    expect(attribute("video", "width"))->toEqual(Some("1750"))
    expect(attribute("video", "height"))->toEqual(Some("1116"))
    expect(attribute("video", "poster"))->toEqual(Some("/lp/fast-build-preview.avif"))
    expect(attribute("video", "controls"))->toEqual(Some(""))
    expect(attribute("video source", "src"))->toEqual(
      Some("https://assets-17077.kxcdn.com/videos/fast-build-3.mp4"),
    )
    expect(attribute("video source", "type"))->toEqual(Some("video/mp4"))
  },
)
