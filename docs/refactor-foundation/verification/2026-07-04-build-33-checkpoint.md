# Build 33 Checkpoint

Date: 2026-07-04

## Included Changes

- Merged `origin/cursor/book-aesthetic-design-pass-d69a` into `main`.
- Includes the design/aesthetic pass:
  - bookbinding palette additions
  - calmer motion layer
  - paper-card styling for form/list interiors
  - collections and tags surfaced in Library
  - camera-first add-book path and floating capture controls
- App target build number is set to `33`.

## Local Verification

- Project file validation:
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - Result: passed before the build bump.
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
  - Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.04_22-54-48-+0100.xcresult`

## Compile Warnings To Follow Up

- `.symbolEffect(.bounce)` is used in `EmptyStateView` and `ErrorView`; Xcode warns that this effect is iOS 18+ while the app deployment target is iOS 17.
- Existing Swift 6 sendability warnings remain in capture/batch services.

## Remaining Release Check

- Archive and export build 33.
  - Done 2026-07-04 22:56 BST.
- Upload build 33 to App Store Connect.
  - Done 2026-07-04 22:57 BST; upload succeeded and Apple reported the package is processing.
- Confirm App Store Connect processing reaches `VALID`.
  - Confirmed `VALID` 2026-07-04 23:01 BST.
  - App Store Connect build id: `a0e7a806-470c-4da9-8e54-a3498c72fdbb`.
  - `usesNonExemptEncryption: false`.
- Confirm TestFlight device smoke against the uploaded build.
  - Pending on a physical device.
