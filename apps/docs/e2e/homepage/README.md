# Homepage E2E Tests

The `.res` specs compile to `.cy.jsx` and run against the production build with
`cypress.homepage.config.mjs`. From `apps/docs`, run `yarn test:e2e` to build the
site and start the temporary test server. Chrome must be installed.

These tests cover prerendered content, hydration, navigation, clipboard feedback
and contents, and image loading. Their support module fails on console errors
and does not suppress React hydration exceptions.

`DocsRoot` includes Cypress's supported `data-cy-bootstrap` script slot through
`CypressBootstrap.res`. Cypress replaces the slot's contents instead of inserting
extra nodes into the document React hydrates. The comment placeholder makes
React expect a text child; `suppressHydrationWarning` applies only to this script,
whose contents intentionally differ under Cypress. The support module asserts
that Cypress actually uses the slot.

This replaces the custom script-and-whitespace removal workaround. See
[Cypress's React hydration guidance](https://docs.cypress.io/app/references/error-messages#react-hydration-errors).
