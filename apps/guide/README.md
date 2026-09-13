# ReScript Guide

The guide is a standalone, pre-rendered interactive learning application. It
loads lessons from `app/lessons/`, compiles the learner's ReScript in the
browser, and deploys as a Cloudflare Worker with static assets.

This document intentionally describes the application and its authoring
contract only. Lesson copy belongs to the guide author.

## Layout

| Path                              | Purpose                                          |
| --------------------------------- | ------------------------------------------------ |
| `app/lessons/`                    | Lesson MDX files and metadata                    |
| `app/GuideLessonContent.res`      | Build-time lesson discovery and validation       |
| `app/GuideHome.res`               | Guide workspace UI                               |
| `app/GuideCompilerBridgeHook.res` | Browser compiler and execution integration       |
| `styles/main.css`                 | Guide-only visual system and responsive behavior |
| `__tests__/`                      | Browser and unit coverage for the guide          |

## Lesson Contract

Every `.mdx` file under `app/lessons/` is discovered recursively and ordered by
its integer `position`. The build requires these frontmatter fields:

| Field                     | Required | Meaning                                                |
| ------------------------- | -------- | ------------------------------------------------------ |
| `position`                | Yes      | Integer lesson order                                   |
| `id`                      | Yes      | Stable URL-safe hash and lesson identifier             |
| `missionLabel`            | Yes      | Short lesson label                                     |
| `title`                   | Yes      | Lesson heading                                         |
| `description`             | Yes      | Lesson summary used by the lesson model                |
| `exercise.id`             | Yes      | Stable identifier for saved code and completion        |
| `exercise.title`          | Yes      | Exercise label                                         |
| `exercise.initialCode`    | Yes      | Initial editor contents                                |
| `exercise.expectedOutput` | No       | Matching runtime log line that unlocks the next lesson |

Lesson and exercise identifiers are durable client-side storage keys. Do not
rename a published identifier without a migration or an explicit decision to
discard existing learner progress.

Lesson IDs must be URL-safe slugs made from lowercase ASCII letters, digits,
and hyphens. Exercise IDs may use the established slash-delimited form.

An exercise without `expectedOutput` is parsed as a manual check, but manual
checks are not currently completable. Published lessons therefore need a
deterministic `expectedOutput` until another completion mechanism exists.

## Local Development

From the repository root:

```sh
yarn dev:res
```

In a second terminal:

```sh
yarn dev:guide
```

For a production build and test run:

```sh
yarn build:guide
yarn workspace @rescript-lang/guide ci:test
```

`yarn build:guide` compiles ReScript, pre-renders `/`, and copies the client
assets to `apps/guide/out/` for Wrangler. The guide fetches available compiler
versions from `https://cdn.rescript-lang.org` during pre-rendering; the
interactive compiler and runtime then run in the learner's browser.

## Current Capability

- MDX lesson discovery, validation, numeric ordering, and hash-based deep links.
- A desktop workspace with an editable ReScript program, compiler diagnostics,
  type hints, and captured runtime output.
- Exact-output checkpoints that gate forward navigation and persist completion,
  editor drafts, pane sizes, and theme in browser local storage.
- Browser history support, light and dark themes, resizable instruction/output
  panes, Cloudflare preview deployments, and production deployment from
  `master`.

The current interface is intentionally desktop-only: widths below `1024px`
show a stop screen rather than a usable guide.

## Production Checklist

Before launch, complete and verify the following:

- [ ] Author, review, and run every lesson using its real expected output.
- [ ] Add a content-validation test for the complete lesson set, including
      unique `position`, lesson IDs, and exercise IDs.
- [ ] Decide and implement the completion model for exercises that cannot use
      exact runtime output.
- [ ] Decide the public URL and configure the Cloudflare Worker custom domain,
      redirects, and canonical metadata.
- [ ] Add launch metadata and assets: description, social preview, favicon,
      robots policy, and sitemap/discovery strategy.
- [ ] Make the workspace usable on the supported accessibility paths: keyboard
      resize controls, visible focus states, and screen-reader announcements for
      compiler and checkpoint changes.
- [ ] Choose mobile support or explicitly publish the desktop-only constraint
      with an alternate learning path.
- [ ] Split or defer the initial compiler/editor code so the initial route is
      within the agreed performance budget.
- [ ] Replace the deprecated Vite `envFile` configuration and resolve the
      guide workspace's `@types/react` peer-dependency warning.
- [ ] Add a release smoke test against the Cloudflare preview: page load,
      compiler availability, a successful checkpoint, deep link, persistence, and
      final redirect.
- [ ] Define production ownership for compiler-CDN availability, deployment
      rollback, error monitoring, and learner support.

## Deployment

The `deploy-guide` job in `.github/workflows/deploy.yml` builds the guide and
deploys it with Wrangler. Pushes to `master` deploy the production Worker;
non-Dependabot pull requests from this repository receive a preview Worker
version and a link in the pull request.
