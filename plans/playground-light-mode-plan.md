# Playground Light Mode Implementation Plan

## Goal

Add light mode support to the Playground and let users switch between dark/light from the Settings tab, with persistent preference.

## Status

- Overall: `In progress`
- Owner: `Codex + Josh`
- Last updated: `2026-04-16`

## Scope

- In scope:
  - Theme model for Playground (`Dark | Light`)
  - Settings UI toggle to switch theme
  - Persist theme in `localStorage`
  - Apply theme to CodeMirror editor
  - Apply theme to JavaScript tab syntax highlighting
  - Apply theme to Playground shell/container styles as needed
  - Basic validation (build + targeted tests)
- Out of scope:
  - Global site-wide light/dark mode system
  - URL/share-link theme parameter

## Decisions

- Default theme: `Dark` (for backward compatibility)
- Persistence key: `playgroundTheme` (to confirm before implementation)
- Theme updates should apply immediately without page reload

## Implementation Phases

### Phase 1: Theme State + Wiring

- [x] Add Playground-local theme type and conversion helpers
- [x] Read initial theme from `localStorage`
- [x] Persist theme changes to `localStorage`
- [x] Thread theme through Playground modules that need it

### Phase 2: CodeMirror Theme Support

- [x] Add `Theme` type to `src/components/CodeMirror.res` + `.resi`
- [x] Add `theme` to `editorConfig`
- [x] Add theme compartment to editor instance
- [x] Implement `themeToExtension` for dark and light variants
- [x] Add `editorSetTheme` API for runtime switching

### Phase 3: Settings Toggle

- [x] Add “Playground Theme” section in Settings tab
- [x] Reuse existing toggle/select UI patterns
- [x] Wire setting change to state + `editorSetTheme`

### Phase 4: Visual Integration

- [x] Switch JS tab highlighting from hardcoded dark to selected theme
- [x] Adjust playground shell classes for both themes
- [x] Ensure contrast/readability in Output, JS, Problems, Settings tabs
- [ ] Add any minimal scoped CSS needed for scrollbar/theme polish

### Phase 4.5: Feature Toast

- [x] Show a “new light mode” toast on Playground
- [x] Add dismiss action
- [x] Auto-hide after 10 seconds
- [x] Persist toast “seen” state to avoid repeated display

### Phase 5: Verification

- [ ] `yarn build:res`
- [ ] `yarn test` (or focused checks if full suite is slow)
- [ ] Update/add Playground e2e test for:
  - [ ] Toggle to light mode
  - [ ] Reload persistence
  - [ ] Editor and JS panel theme effect

## Risks / Watchouts

- CodeMirror theme must remain readable for diagnostics (warnings/errors) in both modes.
- Playground has many hardcoded dark utility classes; missing one can cause mixed-theme UI.
- Avoid touching generated `.jsx` files; only edit `.res`/`.resi`/CSS sources.

## Progress Log

- `2026-04-16`: Plan document created.
- `2026-04-16`: Implemented light/dark theme state, CodeMirror runtime theming, settings toggle, JS tab theme support, and new light mode toast behavior.

## Open Questions

- Should theme preference remain local to Playground only (recommended), or align with any future site-wide preference?
- Confirm persistence key name: `playgroundTheme`?
