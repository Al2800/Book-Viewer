# TestFlight Build 31 Verification

Build 31 ships the extraction-review fixes and the frontend copy trim.

## Scope

- iOS build number: `31`
- Marketing version: `1.0`
- Commits: `f022593` (extraction fixes), `478cb1b` (UI trim), pushed to `origin/main`.

Behavior changes:

- Batch capture now runs `ImageQualityAnalyzer` (lenient) on every page inside `BatchCapturePageStore`, stores the score on `PageCapture`, and surfaces the quality warning pill in `BatchCaptureView` (previously dead code).
- `ExtractionReviewView` checks all quotes for duplicates before saving. Flagged quotes present `DuplicateWarningSheet` one at a time; only approved quotes persist.
- UI copy trim: summary cards reduced to stat pills, capture hint card collapsed to a single tip line, redundant row subtitles removed across Capture, Library, Book Selection, and Settings. Row title/subtitle stacks now use `Spacing.xxs`.

## Simulator Verification

Extraction fix gate (all passed, iPhone 17 / iOS 26.5 simulator):

```sh
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/BatchCapturePageStoreTests \
  -only-testing:BookQuotesTests/BatchCaptureLifecycleStateTests \
  -only-testing:BookQuotesTests/CaptureSessionTests \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesTests/ExtractionReviewProcessorTests \
  -only-testing:BookQuotesTests/DuplicateDetectionFlowTests
```

Result: 0 failures.

Simulator build after UI trim:

```sh
xcodebuild build -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result: passed.

Manual simulator smoke with seeded UI-test data (`--uitesting --preload-library-test-data --app-store-media --media-screen <name>`):

- Library rendered with seeded books, pill-only summary card, and subtitle-free Browse rows.
- Capture entry rendered pill bar, three-mode card with short subtitles, and single tip line.
- Settings rendered with subtitles only on Marking Definitions, Auto-process Queue, and Export Quotes.

Screenshots:

- `docs/refactor-foundation/verification/screenshots/build-31-2026-07-04/01-library-seeded.png`
- `docs/refactor-foundation/verification/screenshots/build-31-2026-07-04/02-capture-entry.png`
- `docs/refactor-foundation/verification/screenshots/build-31-2026-07-04/03-settings-entry.png`

## Archive and Upload

Build number changed:

```text
CURRENT_PROJECT_VERSION = 31
```

Archive:

```sh
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-31.xcarchive \
  -allowProvisioningUpdates
```

Result: archive succeeded (`CFBundleVersion = 31`).

Upload:

```sh
xcodebuild -exportArchive \
  -archivePath artifacts/release/BookQuotes-31.xcarchive \
  -exportPath artifacts/release/BookQuotes-31-export \
  -exportOptionsPlist artifacts/release/ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates
```

Result: `Uploaded BookQuotes`, `** EXPORT SUCCEEDED **`.

## App Store Connect

Status command:

```sh
BUILD_NUMBER=31 node scripts/appstoreconnect_status.js
```

Result:

- Build ID: `1977b669-0269-4518-8dc5-ab1553500265`
- Uploaded date: `2026-07-04T04:38:06-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` has `hasAccessToAllBuilds: true` and includes tester Alastair Campbell.

## TestFlight Checklist

Use build 31 to verify:

- batch capture shows the quality warning pill after a blurry/dark page;
- saving a quote that already exists in the book presents the duplicate warning sheet;
- "Save Anyway" persists the duplicate, "Cancel" skips it while saving the rest;
- Capture, Library, and Settings screens read cleanly with the trimmed copy;
- real-device camera framing and live model extraction remain unaffected by the page-store change.

## Remaining Risk

- Duplicate review is sequential per flagged quote; a large batch with many duplicates presents several sheets in a row.
- Offline batch double-processing path (queue + review) is still open, as is the Gemini/HF backend split for offline vs online extraction.
