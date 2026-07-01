# 2026-07-01: Submission Checkpoint and Build 30

## Scope

This checkpoint verifies the refactor foundation before starting frontend feature work, then prepares build 30 for TestFlight device smoke.

## Current Model Configuration

The iOS app uses the model-assisted quote extraction path first:

```text
ExtractionReviewView
-> ModelAssistedQuoteExtractor
-> RemoteModelQuoteExtractor
-> POST https://api.bookquotes.uk/api/extract-quotes-hf
-> Cloudflare Worker
-> Hugging Face router
```

The backend default model is:

```text
Qwen/Qwen2.5-VL-72B-Instruct:preferred
```

Production backend checks:

- `https://api.bookquotes.uk/health` returned `{"status":"ok","version":"1.0.0"}`.
- `wrangler secret list --env production` shows `HF_API_TOKEN` and `HF_MODEL_ID` configured as production secrets.
- `wrangler.toml` production has `ALLOW_AUTHENTICATED_EXTRACTION = "true"`.

The app-side remote request uses:

- endpoint: `/api/extract-quotes-hf`;
- temperature: `0.1`;
- max output tokens: `4096`;
- response MIME type: `application/json`;
- extraction source stamped as `model_assisted` when the remote route succeeds.

## Simulator Verification

Focused extraction/refactor gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/GeminiServiceTests \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesTests/PageCaptureTests
```

Result:

- 55 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-33-29-+0100.xcresult`

Capture abstraction gate:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesTests/QuoteCaptureSessionStoreTests \
  -only-testing:BookQuotesTests/QuoteCaptureImageProcessorTests \
  -only-testing:BookQuotesTests/BatchCapturePageStoreTests \
  -only-testing:BookQuotesTests/ExtractionReviewProcessorTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesTests/PageQuoteEditorListTests \
  -only-testing:BookQuotesTests/CaptureQueueManagerTests \
  -only-testing:BookQuotesTests/CaptureQueueStoreTests \
  -only-testing:BookQuotesTests/CaptureQueueProcessingTests \
  -only-testing:BookQuotesTests/CaptureQueueRetryCoordinatorTests \
  -only-testing:BookQuotesTests/CaptureQueueStatsReporterTests \
  -only-testing:BookQuotesTests/CameraPreviewSizeStoreTests \
  -only-testing:BookQuotesTests/CameraAuthorizationPolicyTests
```

Result:

- 46 tests executed.
- 0 failures.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-40-08-+0100.xcresult`

Simulator build:

```sh
xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7'
```

Result: passed.

Manual simulator smoke:

- Installed and launched the simulator app with seeded UI-test data.
- Verified seeded Library rendered with 3 books and 10 quotes.
- Verified Capture entry rendered with Add New Book, Capture Quotes, and Batch Mode.
- Verified Settings entry rendered with account, capture, display, and data sections.

Screenshots:

- `docs/refactor-foundation/verification/screenshots/submission-checkpoint-2026-07-01/01-library-seeded.png`
- `docs/refactor-foundation/verification/screenshots/submission-checkpoint-2026-07-01/02-capture-entry.png`
- `docs/refactor-foundation/verification/screenshots/submission-checkpoint-2026-07-01/03-settings-entry.png`

XCUITest smoke:

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,id=AF90E17A-F07E-40FB-B32E-C52FFCA09DE7' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_CropAccept_DismissesReviewBeforeProcessing \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_ThumbnailDetail_CanRemoveCapture \
  -only-testing:BookQuotesUITests/SearchFlowTests/testSearch_Query_ShowsResults \
  -only-testing:BookQuotesUITests/BookRegistrationFlowTests/testEditBook_ModifyTitle_SavesChanges \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_PrivacyPolicySheet_OpensLegalContent \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_TermsOfServiceSheet_OpensLegalContent \
  -only-testing:BookQuotesUITests/MarkingDefinitionsFlowTests/testSettingsRoot_ExportQuotesSheet_StillOpens
```

Result: blocked before app assertions.

- Failure: `Timed out waiting for AX loaded notification`.
- Result bundle: `/Users/user298279/Library/Developer/Xcode/DerivedData/BookQuotes-chdblwnjsdsclucdtkuelvsnfrxn/Logs/Test/Test-BookQuotes-2026.07.01_08-36-16-+0100.xcresult`
- This matches issue `081-xcuitest-ax-runner-initialization.md`.

## TestFlight Build 30

Build number changed:

```text
CURRENT_PROJECT_VERSION = 30
```

Archive:

```sh
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-30.xcarchive
```

Result: archive succeeded.

Upload:

```sh
xcodebuild -exportArchive \
  -archivePath artifacts/release/BookQuotes-30.xcarchive \
  -exportPath artifacts/release/BookQuotes-30-export \
  -exportOptionsPlist artifacts/release/ExportOptions-TestFlight.plist
```

Result:

- Export succeeded.
- Upload succeeded.
- App Store Connect reported: `Uploaded package is processing.`

App Store Connect polling:

```sh
BUILD_NUMBER=30 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result at checkpoint time:

- Build 30 was not yet visible through the builds API.
- Internal beta group `Test v1` still has `hasAccessToAllBuilds = true` and includes tester `Alastair Campbell`.

## Residual Risk

- Real TestFlight device smoke cannot be completed until App Store Connect finishes processing build 30 and makes it available in TestFlight.
- XCUITest UI automation remains blocked by issue 081, so simulator user-flow coverage is a combination of unit gates and manual seeded screenshots.
- Real-device camera lens/framing and live model extraction quality still need TestFlight validation with the known marked-page cases.
