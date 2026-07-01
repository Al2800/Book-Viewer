# Quote Tag Mutation Refactor Characterization

Date: 2026-07-01

## Behaviour Characterized

Adding and removing a tag from a quote should preserve the relationship invariant:

- adding a tag appends the tag to `quote.tags`,
- adding a tag appends the quote to `tag.quotes`,
- adding a tag updates `quote.dateModified`,
- removing a tag removes the tag from `quote.tags`,
- removing a tag removes the quote from `tag.quotes`,
- removing a tag updates `quote.dateModified`.

## Tests Added

- `BookQuotesTests/Unit/Models/QuoteTagMutationTests.swift`

The tests exercise the relationship mutation without launching SwiftUI, opening the tag sheet, or saving SwiftData.

## Refactor Shape

- `QuoteTagMutation` owns deterministic quote-tag relationship mutation.
- `AddTagToQuoteSheet` keeps available-tag presentation, create-tag sheet state, model-context save, and dismissal.

## Acceptance Criteria Covered

- The same observable quote/tag relationships are mutated as the previous inline implementation.
- The modified-date side effect is directly characterized.
- The new seam concentrates the relationship invariant for future tag-management changes.
