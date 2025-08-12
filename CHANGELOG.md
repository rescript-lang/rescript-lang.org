# Changelog

This changelog documents significant changes that caused a new version in the manual, or other related resources.

We don't create a version fork for every minor release, and try to make docs "append only" as much as possible. Usually when we introduce a new feature we add a `since 9.0` annotation to a specific section, and be done with it.

For bigger substantial changes (e.g. when we removed the `bs.` prefix, or introduced the `rescript` package in 9.1.0), we fork the version to have a cleaner look on the actual state.

Here are the notes on major changes we did, and how the version corresponds to specific version ranges.

## Manual

### latest

- ## 9.1 related

### v9.0 (v8.3 - v9.0)

**Related PR:** (https://github.com/rescript-association/rescript-lang.org/pull/293)

- 8.3 related
  - Removes `bs.` prefixes from attributes
  - Allow more character sets in module names
- 8.4 related
  - Pinned deps feature page
  - New 109 warning toplevel expression is expected to have type unit It is turned on as warn-error by default. This warning is introduced to avoid partial application errors in a curried language
- 9.0 related
  - Lightweight polyvar syntax
  - New external-stdlib docs
  - `when` -> `if` transformation

### v8.0.0 (v6 - v8.3)

- Docs with Reason / OCaml syntax before the new syntax
