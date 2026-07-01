# Issue 082: Test Fixtures Modular Refactor

Status: `closed`

## Context

`BookQuotesTests/Infrastructure/TestFixtures.swift` is 642 LOC, above the sub-500 LOC target. It mixes unrelated fixture concerns:

- books and quotes.
- marking definitions, collections, and tags.
- capture sessions, page captures, and queue items.
- search-performance datasets.
- generated image fixtures and OCR cover fixtures.

The broad unit gate is green before this refactor, so this slice should be a behaviour-preserving split of test infrastructure only.

## Acceptance Criteria

- Preserve the existing `TestFixtures` public call sites.
- Keep each resulting fixture file below 500 LOC.
- Keep fixture behavior unchanged.
- Do not change production code.
- Run a focused fixture-dependent test set after the split.
- Run the broad unit gate after the split because fixture helpers are widely used.
- Record verification output.

## Implementation

- Split `TestFixtures.swift` into focused `TestFixtures` extensions:
  - base namespace file.
  - book and quote fixtures.
  - organization fixtures.
  - capture fixtures.
  - search and image fixtures.

## Verification

```bash
plutil -lint BookQuotes.xcodeproj/project.pbxproj
```

Result: passed.

```bash
git diff --check
```

Result: passed.

Focused fixture-dependent gate:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/BookModelTests \
  -only-testing:BookQuotesTests/QuoteModelTests \
  -only-testing:BookQuotesTests/CollectionModelTests \
  -only-testing:BookQuotesTests/TagModelTests \
  -only-testing:BookQuotesTests/CaptureSessionTests \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/CaptureQueueItemTests \
  -only-testing:BookQuotesTests/MemoryPerformanceTests/testMemory_Load1000Quotes_Acceptable \
  -only-testing:BookQuotesTests/VisionOCRCoverExtractionIntegrationTests
```

Result: passed.

- 77 tests executed.
- 0 failures.

Broad unit gate after fixture split:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' -only-testing:BookQuotesTests
```

Result: passed.

- 548 tests executed.
- 0 failures.

Fixture file sizes after the split:

- `TestFixtures+OCRCoverFixtures.swift`: 236 LOC.
- `TestFixtures+Capture.swift`: 117 LOC.
- `TestFixtures+BooksQuotes.swift`: 109 LOC.
- `TestFixtures+SearchImages.swift`: 107 LOC.
- `TestFixtures+Organization.swift`: 81 LOC.
- `TestFixtures.swift`: 6 LOC.

## Follow-Up

- If any fixture extension grows toward 500 LOC, split by domain again rather than creating generic helpers.
