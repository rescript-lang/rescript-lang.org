# Contributing

Thanks for considering contributing to our platform. We really appreciate the help and would like to give you some tips on how to contribute in the most effective way.

Please make sure to check out our [Code of Conduct](CODE_OF_CONDUCT.md) and make sure to follow it in all your interactions within this project and the community.

## Ways to contribute

- Writing docs for the manual (Check for issues that are marked with a [`manual`](https://github.com/rescript-lang/rescript-lang.org/issues?q=is%3Aissue+is%3Aopen+label%3A"manual") and [`help wanted`](https://github.com/rescript-lang/rescript-lang.org/issues?q=is%3Aissue+is%3Aopen+label%3A"help+wanted") tag)
- Joining in discussions on our [issue tracker](https://github.com/rescript-lang/rescript-lang.org/issues)
- Give feedback for improvements (incomplete / missing docs, bad wording,
  search user experience / design, etc.)
- Advanced: Help building platform features (design system, automatic testing, markdown parsing, etc.)

## How to get started?

### Find an issue

Before you start any work or submit any PRs, make sure to check our [issue tracker](https://github.com/rescript-lang/rescript-lang.org/issues) for any issues or discussions on the topic.

If you can't find any relevant issues, feel free to create a new one to start a discussion. We usually assign issues to a responsible person to prevent confusion and duplicate work, so always double check if an issue is currently being worked on, or talk to the current assignee to take over the task.

**Always make sure to get feedback from the core maintainers before starting any work**

The project follows very specific goals and tries to deliver the highest value with the least amount of resources. Please help us focus on the tasks at hand and don't submit any code / bigger refactorings without any proper discussion on the issue tracker. Otherwise your PR might not be accepted!

If you need inspiration on what to work on, you can check out issues tagged with [`good first issue`](https://github.com/rescript-lang/rescript-lang.org/issues?q=is%3Aissue+is%3Aopen+label%3A"good+first+issue") or [`help wanted`](https://github.com/rescript-lang/rescript-lang.org/issues?q=is%3Aissue+is%3Aopen+label%3A"help+wanted").

### Discuss an issue

We really appreciate all input from users, community members and potential contributors. Please make sure to consider the other person's opinion and don't assume any common knowledge.

**Most importantly: Keep it professional and be nice to eachother**

There might be situations where others don't understand a proposed feature or have different opinions on certain writing styles. That's fine, discussions are always welcome! Communicate in clear actionables, make your plans clear and always to stick to the original topic.

If other contributors disagree with certain proposals and don't change their mind after longer discussions, please don't get discouraged when an issue gets closed / postponed. Everyone tries their best to make the platform better, and to look at it in another perspective: Closed issues are also a highly valuable resource for others to understand technical decisions later on.

### Communicate your Time Commitment

Open Source development can be a challenge to coordinate, so please make sure to block enough time to work on your tasks and show commitment when taking on some work. Let other contributors know if your time schedule changes significantly, and also let others know if you can't finish a task.

We value your voluntary work, and of course it's fine to step back from a ticket for any reasons (we can also help you if you are getting stuck). Please talk to us in any case, otherwise we might re-assign the ticket to other contributors.

### Communication Channels

- [Issue Tracker](https://github.com/rescript-lang/rescript-lang.org/issues)
- [ReScript Discourse (General / mostly unrelated discussions)](http://forum.rescript-lang.org)

## Working on the rescript-lang.org

We try to keep our contribution guidelines to a minimum. Please keep following rules in mind whenever writing code or technical documentation.

### Keep it simple

The less code we write, the better. If there's a way to do rendering on the server, or enhance existing markdown files, we prefer that over client-side rendering and external loading.

We also try to keep our third-party dependencies to a minimum. The site uses ReScript v12, React, React Router, `@mdx-js/mdx`, and `remark`. Please try to keep a small JS footprint, especially for client side code (to keep the bundle size small).

### Repository layout and tooling

This is a Yarn workspace monorepo. The main website and its MDX content live in
`apps/docs/`, the interactive guide lives in `apps/guide/`, and shared code lives
in `packages/playground/` and `packages/shared/`. Run the root commands from the
repository root; use `yarn workspace <name> <command>` to target one workspace.
See the [README](README.md#project-structure-overview) for the directory map.

Use Node.js 26 or newer and the Yarn 4.13.0 release pinned by the repository via
Corepack. `yarn format` runs Oxfmt and formats ReScript across all four workspaces.
The pre-commit hook formats matching staged files and stages its fixes. Edit
ReScript sources rather than generated JavaScript; include regenerated guide
entry modules when their sources change.

### Think about the target audience & UX

The rescript-lang.org project aims to be the best documentation experience for our ReScript users.

Always check if there are any designs for certain UI components and think about how to get the most out for the users. Jumpy UI, slow loading, big assets and bad accessibility is not what we stand for.

### Technical Writing (Documentation)

- Think and write in a JS friendly mindset when explaining concepts / showing examples.
- No `foo` examples if somewhat possible. Try to establish practical context in your show case examples.
- No references to `OCaml`. ReScript is its own language, and we don't rely on external resources of our host language.
- If possible, no references to `Reason` examples / external resources. Our goal is to migrate everything to ReScript syntax.

### Tailwind for CSS Development

The docs site uses [Tailwind CSS v4](https://tailwindcss.com) through the Vite plugin for component styling. Design tokens and custom utilities live in [apps/docs/styles/\_theme.css](apps/docs/styles/_theme.css). If you are not familiar with Tailwind, check out existing components for inspiration.

We sometimes also need to fall back to common CSS (with Tailwind `@apply` directives to enforce our style system). The docs entry point is [apps/docs/styles/main.css](apps/docs/styles/main.css). The guide uses its own plain CSS in [apps/guide/styles/main.css](apps/guide/styles/main.css).

**Only fall back to plain CSS if absolutely necessary**

Most of the stuff we want to build can be built as components with Tailwind classes. We mostly use global CSS if we need to interact with 3rd party code (such as `highlightjs`), or if we need features like child selectors (markdown rendering with nested lists).

## PR process

- Clone the project and follow the [README](README.md) instructions
- Always run the page locally and verify your changes (especially when working on code examples)
- When writing markdown with code examples, run `CI=1 yarn test` to check examples, relative links, and redirects with CI's link-check failure behavior. See the [README](README.md#markdown-example-and-link-checks) for targeted example checks and script working directories.
- Feel free to open `Draft PRs` when you are working on bigger features (good for visibility and asking for feedback)
- Improve code based on last feedback until the code is ready to be merged
