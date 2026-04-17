Dark Mode Migration Plan

## Current State

### How dark mode works today

- Theme is toggled via `SiteTheme.res`, which adds/removes a `site-dark` class on `<html>`.
- A script in `app/root.res` initializes the theme from `localStorage` or `prefers-color-scheme` on page load to prevent FOUC.
- Tailwind `dark:` is now enabled through `@custom-variant dark (&:where(.site-dark, .site-dark *));`.
- The landing page, navbar, mobile overlay, footer, and shared heading utilities now use `dark:` classes directly.
- The broad `html.site-dark` override block has been removed from `styles/main.css`.

### The problem

The remaining dark-mode work is no longer about wiring up Tailwind. It is now about finishing the migration and tightening visual consistency across the site:

1. Some component surfaces and text levels still need contrast tuning.
2. Not all shared chrome has been migrated yet, especially older docs navigation paths.
3. The plan docs were written before the current Tailwind migration work landed, so some steps below are now completed.

### Files involved

| File                                     | Role                                                                   |
| ---------------------------------------- | ---------------------------------------------------------------------- |
| `styles/main.css`                        | Tailwind custom dark variant, shared typography utilities, body styles |
| `src/components/LandingPage.res`         | Landing page with hardcoded light-mode text colors                     |
| `src/components/NavbarPrimary.res`       | Navbar theme toggle and dark classes                                   |
| `src/components/NavbarMobileOverlay.res` | Mobile overlay dark classes                                            |
| `src/components/Footer.res`              | Footer dark classes and dark logo swap                                 |
| `src/common/SiteTheme.res`               | Theme toggle logic (adds/removes `site-dark` class)                    |
| `app/root.res`                           | Theme initialization script                                            |

---

## Status

### Completed

1. Added `@custom-variant dark` to `styles/main.css`.
2. Moved `hl-title`, `hl-1` through `hl-5`, and `hl-overline` to use `dark:` colors directly.
3. Replaced the old `body` light/dark split with a single Tailwind rule using `dark:bg-*` and `dark:text-*`.
4. Removed the old `html.site-dark` override block from `styles/main.css`.
5. Migrated the landing page, navbar, mobile overlay, and footer to explicit `dark:` classes.
6. Verified the current changes with `yarn build:res`.

### Remaining Work

1. Audit remaining shared chrome still using older styling paths, especially docs-specific navigation.
2. Improve dark-mode contrast on sections that still feel too dim or flat.
3. Add test coverage for site-wide theme toggling and dark-mode homepage regressions.

## Implementation Notes

- Prefer Tailwind `dark:` classes in components over CSS selectors targeting rendered utility class names.
- Keep `.site-dark` only as the trigger on `<html>`; styling should live in utilities and component class lists.
- Avoid reintroducing `html.site-dark #...` overrides unless there is no component-level alternative.

## Color mapping reference

| Light mode       | Dark mode        | Usage                                              |
| ---------------- | ---------------- | -------------------------------------------------- |
| `text-black`     | `text-gray-20`   | Primary headings (`hl-1`, `hl-2`, `hl-3`)          |
| `text-gray-80`   | `text-gray-20`   | Secondary headings, body text                      |
| `text-gray-60`   | `text-gray-30`   | Subtitles, secondary text                          |
| `text-gray-40`   | `text-gray-30`   | Captions, muted text                               |
| `bg-white`       | `bg-gray-100`    | Page background                                    |
| `bg-gray-10`     | `bg-gray-100`    | Elevated surfaces in light (blend into bg in dark) |
| `border-gray-20` | `border-gray-80` | Borders                                            |
