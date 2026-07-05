# Build 34 Checkpoint

Date: 2026-07-05

## Included Changes

- Merged `origin/cursor/book-aesthetic-design-pass-d69a` at `e46555a`.
- Includes catalog stock covers after cover recognition:
  - cover recognition metadata now carries catalog cover candidates
  - metadata normalisation preserves stock cover URLs where appropriate
  - ISBN lookup support has been extended for catalog cover handling
- App target build number is set to `34`.

## Local Verification

- Project file validation:
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - Result: passed before the build bump.
- Simulator compile:
  - `xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7'`
  - Result: passed.
- Focused tests:
  - `BookQuotesTests/CoverMetadataNormalizerTests`
  - `BookQuotesTests/BatchCapturePageStoreTests`
  - `BookQuotesTests/ExtractionReviewProcessorTests`
  - `BookQuotesTests/ExtractionReviewQuoteStateTests`
  - `BookQuotesTests/PageQuoteEditorListTests`
  - `BookQuotesTests/TagRowPresentationTests`
  - `BookQuotesTests/CollectionModelTests`
  - `BookQuotesTests/TagModelTests`
  - Result: 37 tests, 0 failures.
  - Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.05_08-46-21-+0100.xcresult`

## Compile Warnings To Follow Up

- `.symbolEffect(.bounce)` is used in `EmptyStateView` and `ErrorView`; Xcode warns that this effect is iOS 18+ while the app deployment target is iOS 17.
- Existing Swift 6 sendability warnings remain in capture/batch services.

## Remaining Release Check

- Archive and export build 34.
  - Done 2026-07-05 08:49 BST.
- Upload build 34 to App Store Connect.
  - Done 2026-07-05 08:49 BST; upload succeeded and Apple reported the package is processing.
- Confirm App Store Connect processing reaches `VALID`.
  - Confirmed `VALID` 2026-07-05 08:52 BST.
  - App Store Connect build id: `906d8b6a-359e-47f9-89ae-c9aa2678cd1b`.
- Confirm `usesNonExemptEncryption: false`.
  - Confirmed.
- Confirm TestFlight device smoke against the uploaded build.
  - Pending on a physical device.
