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
  - Pending.
- Upload build 34 to App Store Connect.
  - Pending.
- Confirm App Store Connect processing reaches `VALID`.
  - Pending.
- Confirm `usesNonExemptEncryption: false`.
  - Pending.
- Confirm TestFlight device smoke against the uploaded build.
  - Pending on a physical device.
