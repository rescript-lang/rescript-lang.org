open ReactRouter
open Vitest

let expectedExample = `module Button = {
  @react.component
  let make = (~count) => {
    let times = switch count {
    | 1 => "once"
    | 2 => "twice"
    | n => n->Int.toString ++ " times"
    }
    let text = \`Click me $\{times\}\`

    <button> {text->React.string} </button>
  }
}`

let getOpenGraphImageUrl = () => {
  switch document->WebAPI.Document.querySelector("meta[property='og:image']") {
  | Value(meta) =>
    switch meta->WebAPI.Element.getAttribute("content") {
    | Value(content) => WebAPI.URL.make(~url=content)
    | Null => failwith("expected Open Graph image metadata to have content")
    }
  | Null => failwith("expected Open Graph image metadata")
  }
}

test("landing page Open Graph image targets its absolute page URL", async () => {
  let _screen = await render(
    <MemoryRouter initialEntries=["/"]>
      <LandingPage />
    </MemoryRouter>,
  )
  let pageUrl = WebAPI.URL.make(~url=Env.root_url)
  let imageUrl = getOpenGraphImageUrl()
  let targetUrl = switch imageUrl.searchParams
  ->WebAPI.URLSearchParams.get("url")
  ->Nullable.make
  ->Nullable.toOption {
  | Some(targetUrl) => WebAPI.URL.make(~url=targetUrl)
  | None => failwith("expected Open Graph image URL to include a page URL")
  }

  expect(imageUrl.origin)->toBe(pageUrl.origin)
  expect(imageUrl.pathname)->toBe("/ogimage/index.png")
  expect(targetUrl.href)->toBe(pageUrl.href)
})

test(
  "landing page playground link uses compressed code that the playground can decode",
  async () => {
    let screen = await render(
      <MemoryRouter initialEntries=["/"]>
        <LandingPage />
      </MemoryRouter>,
    )

    let _ = await screen->getByText("Edit this example in Playground")

    let href = switch document->WebAPI.Document.querySelector("a[href*='/try?code=']") {
    | Value(link) =>
      switch link->WebAPI.Element.getAttribute("href") {
      | Value(href) => href
      | Null => failwith("expected landing page playground link to have an href")
      }
    | Null => failwith("expected to find the landing page playground link")
    }

    let {pathname, searchParams} = WebAPI.URL.make(~url=href, ~base="https://rescript-lang.org")

    expect(pathname)->toBe("/try")

    let compressedCode =
      searchParams->WebAPI.URLSearchParams.get("code")->Nullable.make->Nullable.toOption

    let decodedCode =
      compressedCode
      ->Option.getOrThrow
      ->LzString.lzString.decompressFromEncodedURIComponent
      ->Nullable.make
      ->Nullable.toOption

    expect(decodedCode->Option.isSome)->toBe(true)
    expect(decodedCode->Option.getOrThrow)->toBe(expectedExample)
  },
)

test("landing page playground hero renders highlighted code tokens", async () => {
  let screen = await render(
    <MemoryRouter initialEntries=["/"]>
      <LandingPage />
    </MemoryRouter>,
  )

  let _ = await screen->getByText("Write in ReScript")

  let rescriptCodeBlock = switch document->WebAPI.Document.querySelector(
    "[data-testid='landing-playground-hero'] code.lang-res",
  ) {
  | Value(codeBlock) => codeBlock
  | Null => failwith("expected landing playground hero to render the ReScript code block")
  }

  let javascriptCodeBlock = switch document->WebAPI.Document.querySelector(
    "[data-testid='landing-playground-hero'] code.lang-js",
  ) {
  | Value(codeBlock) => codeBlock
  | Null => failwith("expected landing playground hero to render the JavaScript code block")
  }

  expect(rescriptCodeBlock.innerHTML->String.includes("<span"))->toBe(true)
  expect(javascriptCodeBlock.innerHTML->String.includes("<span"))->toBe(true)
})

test("landing page renders its critical sections", async () => {
  let screen = await render(
    <MemoryRouter initialEntries=["/"]>
      <LandingPage />
    </MemoryRouter>,
  )

  let intro = await screen->getByText("JavaScript Made Simple for Humans and AI")
  let playground = await screen->getByText("Write in ReScript")
  let install = await screen->getByText("Quick Install")
  let mainSellingPoint = await screen->getByText("The fastest build system on the web")
  let community = await screen->getByText(
    "A community of programmers who value getting things done",
  )
  let users = await screen->getByText("Trusted by our users")
  let resources = await screen->getByText("Curated resources")

  await element(intro)->toBeVisible
  await element(playground)->toBeVisible
  await element(install)->toBeVisible
  await element(mainSellingPoint)->toBeVisible
  await element(community)->toBeVisible
  await element(users)->toBeVisible
  await element(resources)->toBeVisible
})

test("landing page copy button shows success feedback", async () => {
  let screen = await render(
    <MemoryRouter initialEntries=["/"]>
      <LandingPage />
    </MemoryRouter>,
  )

  let copyButton = await screen->getByLabelText("Copy npm install rescript command")
  await copyButton->click

  let feedback = await screen->getByText("Copied!")
  await element(feedback)->toBeVisible
})

test(
  "landing page playground hero keeps highlight styling in the sandboxed snapshot copy",
  async () => {
    await viewport(1440, 1800)

    let screen = await render(
      <MemoryRouter initialEntries=["/"]>
        <LandingPage />
      </MemoryRouter>,
    )

    let sourceSection = switch document->WebAPI.Document.querySelector(
      "[data-testid='landing-playground-hero']",
    ) {
    | Value(section) => section
    | Null => failwith("expected to find the landing playground hero section")
    }

    let sandboxTestId = "landing-playground-hero-sandbox"
    let snapshotHtml = sourceSection.outerHTML
    await screen->unmount

    let snapshotScreen = await render(
      <div
        dataTestId=sandboxTestId
        style={{width: "1440px", margin: "0"}}
        dangerouslySetInnerHTML={"__html": snapshotHtml}
      />,
    )

    let _ = await snapshotScreen->getByTestId(sandboxTestId)

    let sandbox = switch document->WebAPI.Document.querySelector(
      "[data-testid='landing-playground-hero-sandbox']",
    ) {
    | Value(sandbox) => sandbox
    | Null => failwith("expected to find the sandboxed landing playground hero")
    }

    let sandboxRect: WebAPI.DOMAPI.domRect = sandbox->WebAPI.Element.getBoundingClientRect

    let rescriptCodeBlock = switch document->WebAPI.Document.querySelector(
      "[data-testid='landing-playground-hero-sandbox'] code.lang-res",
    ) {
    | Value(codeBlock) => codeBlock
    | Null =>
      failwith("expected sandboxed landing playground hero to render the ReScript code block")
    }

    let javascriptCodeBlock = switch document->WebAPI.Document.querySelector(
      "[data-testid='landing-playground-hero-sandbox'] code.lang-js",
    ) {
    | Value(codeBlock) => codeBlock
    | Null =>
      failwith("expected sandboxed landing playground hero to render the JavaScript code block")
    }

    expect(sandboxRect.width > 1000.0)->toBe(true)
    expect(rescriptCodeBlock.innerHTML->String.includes("<span"))->toBe(true)
    expect(javascriptCodeBlock.innerHTML->String.includes("<span"))->toBe(true)
    await snapshotScreen->unmount
  },
)
