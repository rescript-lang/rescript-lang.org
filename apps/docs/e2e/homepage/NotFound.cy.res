open Cypress

it("the static 404 document renders at the requested URL without hydration errors", () => {
  let path = "/docs/react/does-not-exist"
  // The homepage suite uses a static server. Load Pages' error document and
  // give it the unknown URL before React starts, as Pages does in production.
  visitWithOptions(
    "/404.html",
    {
      onBeforeLoad: window => window->windowHistory->replaceState(JSON.Null, "", path),
    },
  )
  containsIn("h2", "Page Not Found")->should("be.visible")->ignore
  cyLocation("pathname")->shouldEqual(path)->ignore
  get(`nav a.text-fire-30[href="/docs/manual/introduction"]`)->should("be.visible")->ignore
  containsIn("a", "Return home")->click->ignore
  containsIn("h1", HomepageHelpers.headline)->should("be.visible")->ignore
})
