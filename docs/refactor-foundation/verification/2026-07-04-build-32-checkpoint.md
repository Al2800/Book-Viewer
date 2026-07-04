# Build 32 Checkpoint

Date: 2026-07-04

## Included Changes

- Carries forward GitHub `main` at `b4904b1`.
- App target build number is set to `32`.
- Includes the build 31 TestFlight verification note updates.

## Local Verification

- Project file validation:
  - `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
  - Result: passed.
- Simulator compile:
  - `xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7'`
  - Result: passed.
- Focused capture/review tests:
  - `BookQuotesTests/BatchCapturePageStoreTests`
  - `BookQuotesTests/ExtractionReviewProcessorTests`
  - `BookQuotesTests/ExtractionReviewQuoteStateTests`
  - `BookQuotesTests/PageQuoteEditorListTests`
  - Result: 11 tests, 0 failures.
  - Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.04_22-17-19-+0100.xcresult`

## Remaining Release Check

- Archive and export build 32.
- Upload build 32 to App Store Connect.
- Confirm App Store Connect processing reaches `VALID`.
- Confirm TestFlight device smoke against the uploaded build.
