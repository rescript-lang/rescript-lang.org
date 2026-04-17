# Dark Mode Handoff (Current Status)

## What We Completed

### 1) Playground dark/light support

- Added a `Playground Theme` toggle in Settings.
- Added runtime CodeMirror theme switching (dark/light).
- Added theme persistence for playground via `localStorage` key:
  - `playgroundTheme`
- Updated JS output panel highlighting to follow playground theme.

### 2) Playground onboarding toast

- Added “New: Light Mode” toast in Playground.
- Supports:
  - `Dismiss`
  - `Try it now` (switches to light mode + closes toast)
  - auto-close after 10s
- Toast “seen” state moved to `sessionStorage` key:
  - `playgroundLightModeToastSeen`

### 3) Playground visual fixes

- Improved light-mode contrast for:
  - Auto-run toggle text
  - Middle panel divider appearance
- Added Cypress flow to:
  - click toast `Try it now`
  - switch back to dark mode from Settings

### 4) Site-wide dark mode foundation (first pass)

- Added global site theme model:
  - `src/common/SiteTheme.res`
  - `src/common/SiteTheme.resi`
- Added early root theme initialization script in `app/root.res`.
- Added navbar theme toggle in `src/components/NavbarPrimary.res`.
- Added dark-mode styling hooks for shared chrome in `styles/main.css`:
  - body
  - primary navbar
  - docs subnav
  - mobile overlay
  - footer
- Added footer dark-logo swap and footer dark classes in `src/components/Footer.res`.

### 5) Tailwind dark-mode migration pass

- Enabled Tailwind dark mode via:
  - `@custom-variant dark (&:where(.site-dark, .site-dark *));`
- Migrated shared typography utilities to include dark colors directly:
  - `hl-title`
  - `hl-1` through `hl-5`
  - `hl-overline`
- Replaced the old `html.site-dark body` override with a single Tailwind body rule.
- Removed the broad `html.site-dark` selector block from `styles/main.css`.
- Migrated these areas to explicit `dark:` classes:
  - landing page
  - navbar
  - mobile overlay
  - footer

## Files Changed (Dark Mode Work)

- `app/root.res`
- `src/common/SiteTheme.res`
- `src/common/SiteTheme.resi`
- `src/components/NavbarPrimary.res`
- `src/components/NavbarMobileOverlay.res`
- `src/components/Footer.res`
- `src/components/ToggleButton.res`
- `src/components/CodeMirror.res`
- `src/components/CodeMirror.resi`
- `src/Playground.res`
- `src/components/LandingPage.res`
- `styles/main.css`
- `e2e/Playground.cy.res`

## Current Known Issues

### Homepage (dark mode)

- Some sections still need contrast tuning and more deliberate dark surface hierarchy.
- A few landing page cards and labels still use light-mode-biased values that could be tightened further.

### General

- This is still a foundational implementation, not a complete theme polish pass.
- `yarn build:res` now succeeds in this environment after clearing a stale `lib/rescript.lock`.
- Broader verification is still pending.

## Recommended Next Steps

### Phase 1: Homepage contrast pass (high priority)

1. Make primary marketing text brighter:
   - Hero title/subtitle
   - USP headings and paragraph text
   - Trusted-by and Curated Resources headings
2. Normalize dark backgrounds section-by-section:
   - ensure no remaining light patches
   - keep visual hierarchy with 2–3 dark surface levels
3. Tune card and border contrast:
   - cards in Curated Resources
   - hr/dividers and muted labels

### Phase 2: Global component pass

1. Audit and fix dark-mode contrast in shared UI:
   - doc-sidebars
   - docs subnav
   - search and any remaining shared controls
2. Replace broad selector overrides with cleaner semantic dark classes where needed.
   - This is mostly done for landing/footer/navbar/mobile overlay.
   - Remaining work should continue the same Tailwind-first approach.

### Phase 3: Accessibility + regression checks

1. Check color contrast (target WCAG AA for body text and controls).
2. Run:
   - `yarn build:res`
   - `yarn test`
   - `yarn vitest --browser.headless --run`
3. Add/adjust regression checks for global theme toggle and homepage dark-mode snapshots.

## Suggested Cleanup (after visual stabilization)

- Consolidate theme constants for shared text/surface levels.
- Avoid overly broad selectors in `styles/main.css` and scope to specific component wrappers.
- Decide final UX for theme toggle location (navbar-only vs additional settings entry).
