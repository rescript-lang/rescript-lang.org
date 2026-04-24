# Meta Description Shortening Design

## Scope

Adjust the Open Graph and Twitter description shortening logic so it:

- always uses the first sentence
- appends the second sentence only when both the first and second sentences are each `<= 140` characters after whitespace normalization
- collapses embedded line breaks and repeated whitespace into single spaces before sentence analysis

This change applies only to the shortened social preview description. The page-level `description` meta tag remains unchanged.

## Current State

`src/components/Meta.res` currently contains an inline helper that splits on `"."` and returns only the first sentence fragment. That implementation does not:

- normalize weird whitespace before splitting
- consider whether a short second sentence should be included
- expose the logic in a testable module

## Proposed Design

Move the shortening logic out of `Meta.res` into a dedicated utility module so it can be tested directly with Vitest.

Suggested structure:

- new utility module in `src/common/` for meta description formatting
- `Meta.res` consumes the utility for derived `ogDescription`
- a focused Vitest file covers the utility behavior

## Behavior

1. Normalize the input description by trimming leading and trailing whitespace and collapsing all internal whitespace runs, including line breaks, into single spaces.
2. Split the normalized string into sentence fragments using `"."`.
3. Trim each fragment and ignore empty fragments created by extra punctuation or spacing.
4. If no sentence fragments remain, fall back to the normalized description.
5. If a first sentence exists, return it with terminal punctuation restored.
6. If a second sentence also exists, append it only when:
   - the normalized first sentence is `<= 140` characters
   - the normalized second sentence is `<= 140` characters
7. If either sentence exceeds the threshold, return only the first sentence.

Examples:

- `120 + 90` chars: include both sentences
- `150 + 40` chars: include only sentence 1
- `80 + 160` chars: include only sentence 1
- multiline input: whitespace is collapsed before sentence detection and output assembly

## Testing

Add a dedicated Vitest file that exercises the extracted helper directly. Coverage should include:

- returns the first sentence when only one sentence exists
- includes a short second sentence when both sentences are within the threshold
- excludes the second sentence when the first sentence exceeds the threshold
- excludes the second sentence when the second sentence exceeds the threshold
- collapses line breaks and repeated spaces before evaluating sentence lengths
- ignores empty sentence fragments caused by trailing periods or repeated punctuation

## Notes

- Keep the implementation simple and deterministic. No total-length budget is needed.
- Preserve existing `Meta` behavior outside `ogDescription` and Twitter description derivation.
- Do not edit generated `.jsx` output directly.
