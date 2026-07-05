# Build 36 Checkpoint

Date: 2026-07-05

## Included Changes

- Merged `origin/cursor/book-aesthetic-design-pass-d69a` at `f9238b3`.
- Includes Library and quote UX additions:
  - daily passage support
  - typographic quote sharing
  - Library sort/view mode additions
  - quote organise section
  - new Library content/view mode unit coverage
- App target build number is set to `36`.

## Local Verification

- Simulator compile:
  - `xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7'`
  - Result: passed.
- Focused tests:
  - `BookQuotesTests/LibraryContentModeTests`
  - `BookQuotesTests/LibraryViewModeTests`
  - `BookQuotesTests/BatchCapturePageStoreTests`
  - `BookQuotesTests/ExtractionReviewProcessorTests`
  - `BookQuotesTests/ExtractionReviewQuoteStateTests`
  - `BookQuotesTests/PageQuoteEditorListTests`
  - `BookQuotesTests/TagRowPresentationTests`
  - `BookQuotesTests/CollectionModelTests`
  - `BookQuotesTests/TagModelTests`
  - Result: 25 tests, 0 failures.
  - Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.05_12-30-22-+0100.xcresult`

## Compile Warnings To Follow Up

- Existing Swift 6 sendability warnings remain in search/capture services.
- AppIntents metadata extraction reports no AppIntents dependency; this is informational for the current app.

## Remaining Release Check

- Archive and export build 36.
  - Pending.
- Upload build 36 to App Store Connect.
  - Pending.
- Confirm App Store Connect processing reaches `VALID`.
  - Pending.
- Confirm `usesNonExemptEncryption: false`.
  - Pending.
- Confirm TestFlight device smoke against the uploaded build.
  - Pending on a physical device.
