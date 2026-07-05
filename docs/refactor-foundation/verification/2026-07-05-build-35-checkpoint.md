# Build 35 Checkpoint

Date: 2026-07-05

## Included Changes

- Merged `origin/cursor/book-aesthetic-design-pass-d69a` at `65a3177`.
- Includes capture chrome legibility work for bright camera scenes:
  - capture button contrast updates
  - design system chrome simplification
  - image review and batch capture overlay adjustments
- App target build number is set to `35`.

## Local Verification

- Simulator compile:
  - `xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7'`
  - Result: passed.
- Focused tests:
  - `BookQuotesTests/BatchCapturePageStoreTests`
  - `BookQuotesTests/ExtractionReviewProcessorTests`
  - `BookQuotesTests/ExtractionReviewQuoteStateTests`
  - `BookQuotesTests/PageQuoteEditorListTests`
  - `BookQuotesTests/TagRowPresentationTests`
  - `BookQuotesTests/CollectionModelTests`
  - `BookQuotesTests/TagModelTests`
  - Result: 19 tests, 0 failures.
  - Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.05_09-27-12-+0100.xcresult`

## Compile Warnings To Follow Up

- Existing Swift 6 sendability warnings remain in search/capture services.
- AppIntents metadata extraction reports no AppIntents dependency; this is informational for the current app.

## Remaining Release Check

- Archive and export build 35.
  - Done 2026-07-05 09:29 BST.
- Upload build 35 to App Store Connect.
  - Done 2026-07-05 09:29 BST; upload succeeded and Apple reported the package is processing.
- Confirm App Store Connect processing reaches `VALID`.
  - Confirmed `VALID` 2026-07-05 09:33 BST.
  - App Store Connect build id: `294b1720-5215-4e55-956d-d9ddf407f1e4`.
- Confirm `usesNonExemptEncryption: false`.
  - Confirmed.
- Confirm TestFlight device smoke against the uploaded build.
  - Pending on a physical device.
