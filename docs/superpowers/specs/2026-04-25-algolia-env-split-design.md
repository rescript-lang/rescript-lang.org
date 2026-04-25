# Algolia Env Split Design

Date: 2026-04-25

## Summary

This change keeps the site on its current pre-rendered Cloudflare Pages setup and splits Algolia configuration into:

- public build-time variables for browser search
- private publish-only variables for search index uploads

Fork PRs and any build without the public Algolia variables should still build successfully, but the UI must clearly show that search is unavailable. The search indexing script should continue to skip cleanly when its private publish variables are missing.

## Goals

- Keep the existing static React Router + Cloudflare Pages architecture.
- Do not adopt `@react-router/cloudflare`.
- Make browser search depend only on `VITE_` variables that are safe to bundle.
- Keep Algolia admin credentials out of the browser bundle and out of fork PR builds.
- Make preview and production index names deterministic via CI-computed `dev_` and `prod_` prefixes.
- Make disabled search obvious in the UI and in local/build logs.

## Non-Goals

- Changing the site from prerendered Pages to a Cloudflare Workers runtime app.
- Solving team-wide local secret distribution in this PR.
- Enabling Algolia-backed search for fork preview builds.
- Introducing GitHub Environments. This design uses repo-level variables and secrets only.

## Current Constraints

- The site is prerendered with `ssr: false` and uploaded to Cloudflare Pages as static output.
- Frontend values must be present at build time because Vite bakes `VITE_*` values into the client bundle.
- The deploy workflow builds in GitHub Actions before uploading to Cloudflare Pages, so Cloudflare dashboard vars are not the primary source for these build-time values.
- Fork PR workflows must not receive Algolia secrets or public search variables.

## Environment Contract

### GitHub repo variables and secrets

Public build-time values:

- `ALGOLIA_APP_ID`
- `ALGOLIA_INDEX_BASENAME`
- `ALGOLIA_SEARCH_API_KEY_DEV`
- `ALGOLIA_SEARCH_API_KEY_PROD`

Private publish-only secrets:

- `ALGOLIA_ADMIN_API_KEY_DEV`
- `ALGOLIA_ADMIN_API_KEY_PROD`

### Computed values in CI

The workflow computes the full index name from the base name:

- pull request builds with Algolia config: `dev_${ALGOLIA_INDEX_BASENAME}`
- preview / non-fork PR deploys: `dev_${ALGOLIA_INDEX_BASENAME}`
- production deploys from `master`: `prod_${ALGOLIA_INDEX_BASENAME}`

### Variables exposed to the browser build

The build step exports:

- `VITE_ALGOLIA_APP_ID`
- `VITE_ALGOLIA_INDEX_NAME`
- `VITE_ALGOLIA_SEARCH_API_KEY`

These are the only Algolia values used by the frontend.

### Variables used by the indexing script

The indexing script receives:

- `ALGOLIA_APP_ID`
- `ALGOLIA_INDEX_NAME`
- `ALGOLIA_ADMIN_API_KEY`

These values remain private and are never read from `import.meta.env`.

## Workflow Behavior

### `deploy.yml`

- `pull_request` for non-fork branches uses the `DEV` public key and `DEV` admin key.
- `pull_request` builds target the Algolia `dev_` index prefix, never the `prod_` index prefix.
- `push` to `master` uses the `PROD` public key and `PROD` admin key.
- `workflow_dispatch` keeps the existing `environment` input and maps it to either `DEV` or `PROD`.
- The workflow computes the index name with the matching prefix before running the build.
- The workflow exports both the public `VITE_*` variables and the private indexing variables for the build pipeline.

### `deploy-fork-preview.yml`

- Do not inject any Algolia variables or secrets.
- The build must still succeed.
- Search should render in its disabled state for these builds.
- The indexing step should skip because its private variables are absent.
- Even for pull requests, fork preview builds do not use the Algolia dev index because they receive no Algolia configuration.

### `pull-request.yml`

- Do not inject Algolia variables by default.
- Validation should continue to pass with search disabled.
- Only revisit this if a test later requires Algolia-backed search specifically.

## Application Behavior

### Frontend search availability

Search is enabled only when all of these values are present and non-empty:

- `VITE_ALGOLIA_APP_ID`
- `VITE_ALGOLIA_INDEX_NAME`
- `VITE_ALGOLIA_SEARCH_API_KEY`

If any one is missing, the app treats search as unavailable.

### Disabled UI

When search is unavailable:

- Do not mount the Algolia DocSearch modal.
- Do not wire the search trigger to open the modal.
- Render a visibly disabled search affordance instead of a normal active trigger.
- Include explicit text such as `Search unavailable`.
- Include accessible labeling that explains search is disabled for this build.

The result should be obvious to users rather than silently removing the feature or showing a broken interaction.

### Logging

When the public browser variables are incomplete:

- log a clear message during local development and build startup
- include the missing variable names in the message

Example shape:

`Algolia search disabled: missing VITE_ALGOLIA_APP_ID, VITE_ALGOLIA_INDEX_NAME`

When the indexing variables are incomplete:

- keep the current graceful skip behavior
- log which private variable is missing

## Local Development

- Remove tracked Algolia values from `.env`.
- Developers can opt into local search with untracked local environment files such as `.env.local`.
- If local Algolia values are absent, the site should still run normally with disabled search UI and a console warning.

This keeps local development usable without requiring every contributor to have Algolia credentials.

## Naming Decision

This design uses one Algolia application and separate indices for preview and production:

- `dev_<base>`
- `prod_<base>`

Index naming alone does not create a special Algolia environment. It only scopes records into separate indices. This is sufficient for this PR and avoids introducing a second Algolia application.

## Verification Plan

- Confirm non-fork preview deploys receive `dev_` index names and the `DEV` keys.
- Confirm production deploys receive `prod_` index names and the `PROD` keys.
- Confirm fork preview builds complete without Algolia configuration.
- Confirm the UI renders the disabled search state when public vars are absent.
- Confirm the build/dev logs clearly state why search is disabled.
- Confirm the indexing script skips cleanly when its private variables are absent.

## Open Questions

None for this design. Team distribution of local development variables is intentionally deferred.
