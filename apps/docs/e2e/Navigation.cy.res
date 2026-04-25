open Cy

// Wait for the app to fully hydrate before interacting with links.
// The production build is pre-rendered so React must attach event
// handlers before client-side navigation works.
let waitForHydration = () => {
  getByTestId("navbar-primary")->shouldBeVisible->ignore
  cyWindow()->its("document.readyState")->shouldWithValue("eq", "complete")->ignore
  wait(2000)
}

// Use short, re-queryable selectors to avoid detached DOM issues.
// When React re-renders during navigation, long chains can hold
// references to stale elements. Separate cy.get() calls let Cypress
// re-query from the DOM root on each retry.

let clickNavLink = (~testId, ~text) => {
  get(`[data-testid="${testId}"] a:visible`)
  ->containsChainable(text)
  ->click
  ->ignore
}

let clickMobileNavLink = text => {
  get(`[data-testid="mobile-nav"] a:visible`)
  ->containsChainable(text)
  ->click
  ->ignore
}

let openMobileMenu = () => {
  get(`[data-testid="toggle-mobile-overlay"]`)->should("be.visible")->click->ignore
  get("#mobile-overlay")->should("be.visible")->ignore
}

// -- Desktop (1280x720) -------------------------------------------------------

describe("Desktop Navigation", () => {
  beforeEach(() => {
    viewport(1280, 720)
    visit("/")
    waitForHydration()
  })

  describe("Primary navbar", () => {
    it(
      "should navigate to Docs via navbar link",
      () => {
        clickNavLink(~testId="navbar-primary-left-content", ~text="Docs")
        url()->shouldInclude("/docs/manual/introduction")->ignore
        get("h1")->shouldBeVisible->ignore
      },
    )

    it(
      "should navigate to Playground via navbar link",
      () => {
        clickNavLink(~testId="navbar-primary-left-content", ~text="Playground")
        url()->shouldInclude("/try")->ignore
      },
    )

    it(
      "should navigate to Blog via navbar link",
      () => {
        clickNavLink(~testId="navbar-primary-left-content", ~text="Blog")
        url()->shouldInclude("/blog")->ignore
      },
    )

    it(
      "should navigate to Community via navbar link",
      () => {
        clickNavLink(~testId="navbar-primary-left-content", ~text="Community")
        url()->shouldInclude("/community")->ignore
        get("h1")->shouldBeVisible->ignore
      },
    )

    it(
      "should navigate home via logo after clicking away",
      () => {
        clickNavLink(~testId="navbar-primary-left-content", ~text="Blog")
        url()->shouldInclude("/blog")->ignore

        get("a[aria-label='homepage']")->should("be.visible")->first->click->ignore
        cyLocation("pathname")->shouldWithValue("eq", "/")->ignore
      },
    )
  })

  describe("Secondary navbar", () => {
    it(
      "should navigate through all secondary nav links from Docs",
      () => {
        // Click Docs in primary nav to reveal the secondary nav
        clickNavLink(~testId="navbar-primary-left-content", ~text="Docs")
        url()->shouldInclude("/docs/manual/introduction")->ignore

        // Language Manual
        clickNavLink(~testId="navbar-secondary", ~text="Language Manual")
        url()->shouldInclude("/docs/manual/introduction")->ignore

        // API
        clickNavLink(~testId="navbar-secondary", ~text="API")
        url()->shouldInclude("/docs/manual/api")->ignore

        // Syntax Lookup
        clickNavLink(~testId="navbar-secondary", ~text="Syntax Lookup")
        url()->shouldInclude("/syntax-lookup")->ignore

        // React
        clickNavLink(~testId="navbar-secondary", ~text="React")
        url()->shouldInclude("/docs/react/introduction")->ignore
      },
    )
  })
})

// -- Mobile (375x667) ---------------------------------------------------------

describe("Mobile Navigation", () => {
  beforeEach(() => {
    viewport(375, 667)
    visit("/")
    waitForHydration()
  })

  describe("Primary navbar", () => {
    it(
      "should navigate to Docs via navbar link",
      () => {
        clickNavLink(~testId="navbar-primary-left-content", ~text="Docs")
        url()->shouldInclude("/docs/manual/introduction")->ignore
        get("h1")->shouldBeVisible->ignore
      },
    )

    it(
      "should navigate home via logo after clicking away",
      () => {
        clickNavLink(~testId="navbar-primary-left-content", ~text="Docs")
        url()->shouldInclude("/docs/manual/introduction")->ignore

        get("a[aria-label='homepage']")->should("be.visible")->first->click->ignore
        cyLocation("pathname")->shouldWithValue("eq", "/")->ignore
      },
    )
  })

  describe("Mobile overlay navigation", () => {
    it(
      "should navigate to Playground via mobile menu",
      () => {
        openMobileMenu()
        clickMobileNavLink("Playground")
        url()->shouldInclude("/try")->ignore
      },
    )

    it(
      "should navigate to Blog via mobile menu",
      () => {
        openMobileMenu()
        clickMobileNavLink("Blog")
        url()->shouldInclude("/blog")->ignore
      },
    )

    it(
      "should navigate to Community via mobile menu",
      () => {
        openMobileMenu()
        clickMobileNavLink("Community")
        url()->shouldInclude("/community")->ignore
        get("h1")->shouldBeVisible->ignore
      },
    )
  })

  describe("Secondary navbar", () => {
    it(
      "should navigate through all secondary nav links from Docs",
      () => {
        // Click Docs in primary nav to reveal the secondary nav
        clickNavLink(~testId="navbar-primary-left-content", ~text="Docs")
        url()->shouldInclude("/docs/manual/introduction")->ignore

        // Scroll to top so the secondary nav is visible
        cyScrollTo("top")

        // Language Manual
        clickNavLink(~testId="navbar-secondary", ~text="Language Manual")
        url()->shouldInclude("/docs/manual/introduction")->ignore

        // API
        cyScrollTo("top")
        clickNavLink(~testId="navbar-secondary", ~text="API")
        url()->shouldInclude("/docs/manual/api")->ignore

        // Syntax Lookup
        cyScrollTo("top")
        clickNavLink(~testId="navbar-secondary", ~text="Syntax Lookup")
        url()->shouldInclude("/syntax-lookup")->ignore

        // React
        cyScrollTo("top")
        clickNavLink(~testId="navbar-secondary", ~text="React")
        url()->shouldInclude("/docs/react/introduction")->ignore
      },
    )
  })
})
