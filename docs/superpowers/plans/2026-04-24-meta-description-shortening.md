# Meta Description Shortening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract social meta description shortening into a reusable utility, add focused Vitest coverage, and update `Meta.res` to use the helper for derived Open Graph and Twitter descriptions.

**Architecture:** Add a small string utility module under `src/common/` that normalizes whitespace, chooses the first sentence, and conditionally appends the second sentence when both are within the 140-character threshold. Cover that module directly with a dedicated Vitest file, then replace the inline `Meta.res` helper with the shared utility while keeping the page-level `description` meta tag unchanged.

**Tech Stack:** ReScript v12, Vitest 4 browser mode, React 19, React Router v7, Yarn 4

---

### Task 1: Create the utility and prove the base behavior with a failing test

**Files:**

- Create: `src/common/MetaDescription.res`
- Test: `__tests__/MetaDescription_.test.res`

- [ ] **Step 1: Write the failing test**

```rescript
open Vitest

test("returns the first sentence for a one-sentence description", async () => {
  let result = MetaDescription.shortenForSocialPreview(
    "JavaScript Made Simple for Humans and AI.",
  )

  expect(result)->toBe("JavaScript Made Simple for Humans and AI.")
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `yarn build:res && yarn vitest --run --browser.headless __tests__/MetaDescription_.test.jsx`
Expected: FAIL with a compile error or runtime failure because `MetaDescription.shortenForSocialPreview` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```rescript
let collapseWhitespace = value =>
  value
  ->String.trim
  ->String.replaceAllRegExp(/\s+/g, " ")

let ensurePeriod = sentence =>
  if sentence->String.endsWith(".") {
    sentence
  } else {
    sentence ++ "."
  }

let shortenForSocialPreview = description => {
  let normalized = collapseWhitespace(description)

  switch normalized->String.split(".")->Array.get(0) {
  | Some(firstSentence) => firstSentence->String.trim->ensurePeriod
  | None => normalized
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `yarn build:res && yarn vitest --run --browser.headless __tests__/MetaDescription_.test.jsx`
Expected: PASS for the single test.

- [ ] **Step 5: Commit**

```bash
git add __tests__/MetaDescription_.test.res src/common/MetaDescription.res
git commit -m "feat: add meta description utility"
```

### Task 2: Extend the tests and utility to cover sentence-length and whitespace rules

**Files:**

- Modify: `src/common/MetaDescription.res`
- Modify: `__tests__/MetaDescription_.test.res`

- [ ] **Step 1: Write the failing tests**

```rescript
test("includes the second sentence when both sentences are within 140 characters", async () => {
  let result = MetaDescription.shortenForSocialPreview(
    "JavaScript Made Simple for Humans and AI. ReScript is a strongly typed language that compiles to clean, efficient JavaScript that humans and AI tools can read and understand.",
  )

  expect(result)->toBe(
    "JavaScript Made Simple for Humans and AI. ReScript is a strongly typed language that compiles to clean, efficient JavaScript that humans and AI tools can read and understand.",
  )
})

test("returns only the first sentence when the first sentence exceeds 140 characters", async () => {
  let result = MetaDescription.shortenForSocialPreview(
    "This first sentence is intentionally long enough to cross the one hundred and forty character threshold before it reaches its final word in the sentence. Short follow up.",
  )

  expect(result)->toBe(
    "This first sentence is intentionally long enough to cross the one hundred and forty character threshold before it reaches its final word in the sentence.",
  )
})

test("returns only the first sentence when the second sentence exceeds 140 characters", async () => {
  let result = MetaDescription.shortenForSocialPreview(
    "Short opening sentence. This second sentence is intentionally long enough to cross the one hundred and forty character threshold before it reaches its final word in the sentence.",
  )

  expect(result)->toBe("Short opening sentence.")
})

test("collapses line breaks and repeated spaces before evaluating the sentences", async () => {
  let result = MetaDescription.shortenForSocialPreview(
    "JavaScript Made Simple for Humans and AI.\n\nReScript is a strongly typed language that compiles to clean,    efficient JavaScript that humans and AI tools can read and understand.",
  )

  expect(result)->toBe(
    "JavaScript Made Simple for Humans and AI. ReScript is a strongly typed language that compiles to clean, efficient JavaScript that humans and AI tools can read and understand.",
  )
})

test("ignores empty sentence fragments created by repeated punctuation", async () => {
  let result = MetaDescription.shortenForSocialPreview(
    "First sentence... Second sentence stays short.",
  )

  expect(result)->toBe("First sentence. Second sentence stays short.")
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `yarn build:res && yarn vitest --run --browser.headless __tests__/MetaDescription_.test.jsx`
Expected: FAIL on the new tests because the utility still returns only the first sentence and does not normalize multi-space and newline input correctly.

- [ ] **Step 3: Write minimal implementation**

```rescript
let maxSentenceLength = 140

let collapseWhitespace = description =>
  description
  ->String.trim
  ->String.replaceAllRegExp(/\s+/g, " ")

let sentenceParts = description =>
  description
  ->collapseWhitespace
  ->String.split(".")
  ->Array.map(String.trim)
  ->Array.keep(part => part != "")

let ensurePeriod = sentence =>
  if sentence->String.endsWith(".") {
    sentence
  } else {
    sentence ++ "."
  }

let shortenForSocialPreview = description => {
  let normalized = collapseWhitespace(description)
  let parts = sentenceParts(normalized)

  switch (parts->Array.get(0), parts->Array.get(1)) {
  | (Some(firstSentence), Some(secondSentence))
    if String.length(firstSentence) <= maxSentenceLength &&
       String.length(secondSentence) <= maxSentenceLength =>
    ensurePeriod(firstSentence) ++ " " ++ ensurePeriod(secondSentence)
  | (Some(firstSentence), _) => ensurePeriod(firstSentence)
  | _ => normalized
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `yarn build:res && yarn vitest --run --browser.headless __tests__/MetaDescription_.test.jsx`
Expected: PASS for all `MetaDescription_` tests.

- [ ] **Step 5: Commit**

```bash
git add __tests__/MetaDescription_.test.res src/common/MetaDescription.res
git commit -m "test: cover meta description shortening rules"
```

### Task 3: Replace the inline `Meta` helper with the shared utility

**Files:**

- Modify: `src/components/Meta.res`
- Test: `__tests__/MetaDescription_.test.res`

- [ ] **Step 1: Update `Meta.res` to call the utility**

```rescript
let ogDescription = switch ogDescription {
| None => MetaDescription.shortenForSocialPreview(description)
| Some(description) => description
}
```

Delete the inline `shortenDesciption` helper from `src/components/Meta.res`.

- [ ] **Step 2: Run compilation and the focused test file**

Run: `yarn build:res && yarn vitest --run --browser.headless __tests__/MetaDescription_.test.jsx`
Expected: PASS. `Meta.res` should compile cleanly and the utility tests should stay green.

- [ ] **Step 3: Run a broader regression check**

Run: `yarn ci:test`
Expected: PASS with no failing Vitest browser tests.

- [ ] **Step 4: Commit**

```bash
git add src/components/Meta.res src/common/MetaDescription.res __tests__/MetaDescription_.test.res
git commit -m "fix: shorten social meta descriptions"
```
