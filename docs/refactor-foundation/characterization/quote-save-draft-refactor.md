# Quote Save Draft Refactor Characterization

Date: 2026-06-30

## Behaviour Characterized

Saving an extracted quote should create a validated `Quote` using the extracted quote fields and the selected book:

- text is copied from the extracted quote,
- the selected book is linked,
- marking type is copied,
- confidence is copied,
- page number is copied,
- chapter is copied,
- margin note is copied,
- source image data is attached,
- custom marking definition is preserved when present,
- quote validation still runs before the service inserts the quote.

## Test Added

- `BookQuotesTests/Unit/Services/QuoteSaveDraftTests.swift`

The test exercises quote construction without launching SwiftUI, inserting into SwiftData, saving a model context, or triggering haptics.

## Refactor Shape

- `QuoteSaveDraft` owns deterministic `ExtractedQuote` to validated `Quote` mapping.
- `QuoteSaveService` keeps orchestration, persistence, duplicate checks, book timestamp mutation, context save, and haptics.

## Acceptance Criteria Covered

- Extracted quote mapping produces the same observable `Quote` fields as the previous inline service code.
- Validation remains part of quote construction before model insertion.
- The new seam is tested through a public value interface.
