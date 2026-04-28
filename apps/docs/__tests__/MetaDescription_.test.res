open Vitest

test("returns the first sentence for a one-sentence description", async () => {
  let result = MetaDescription.shortenForSocialPreview("JavaScript Made Simple for Humans and AI.")

  expect(result)->toBe("JavaScript Made Simple for Humans and AI.")
})

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

test(
  "returns only the first sentence when the second sentence exceeds 140 characters",
  async () => {
    let result = MetaDescription.shortenForSocialPreview(
      "Short opening sentence. This second sentence is intentionally long enough to cross the one hundred and forty character threshold before it reaches its final word in the sentence.",
    )

    expect(result)->toBe("Short opening sentence.")
  },
)

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
