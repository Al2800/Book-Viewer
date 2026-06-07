# TestFlight Build 25 Verification

## Scope

Goal: ship the first on-device quote extraction tracer to TestFlight so marked quote pages can be reviewed without requiring Cloudflare, Gemini, or subscription-gated quote extraction.

This is not the full `012-on-device-mark-aware-quote-extraction` issue. It is a controlled TestFlight experiment for clear underlines/highlights/margin marks and readable OCR text.

## Build 25 Changes

- `ExtractionReviewView` now uses on-device quote extraction for quote pages.
- Quote review processing no longer requires network availability before starting.
- New extraction modules:
  - `OnDeviceQuoteExtractor`
  - `VisionPageTextRecognizer`
  - `PageMarkDetector`
  - `QuoteMarkTextSelector`
- Mock-camera single quote capture now draws readable underlined text so simulator smoke tests exercise the local extraction path.
- Privacy/legal text now states marked quote pages are extracted on-device with Apple Vision OCR/local mark detection. Cover extraction and explicit cloud fallback may still use Gemini.

## Build Settings

Observed app target settings before archive:

- Bundle identifier: `com.acampbell.bookquotes`
- Marketing version: `1.0`
- Build number: `25`
- Team: `92XJSN32W4`
- Signing style: Automatic

The test targets kept their existing internal build numbers.

## Focused Release Gate

Command:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Passed.
- Runtime: `55.622` seconds.

Covered:

- Synthetic on-device OCR and underline extraction.
- Page-capture characterization.
- Extraction review quote state behaviour.
- Mock-camera extraction review with extracted quote controls.
- Quote editor text editing.

## Archive

Command:

```bash
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-1.0-25.xcarchive \
  -allowProvisioningUpdates
```

Result:

- Archive succeeded.
- Archive bundle identifier: `com.acampbell.bookquotes`
- Archive version: `1.0`
- Archive build: `25`

## Upload

Export options used:

```text
method = app-store-connect
destination = upload
teamID = 92XJSN32W4
signingStyle = automatic
uploadSymbols = true
manageAppVersionAndBuildNumber = false
```

Command:

```bash
xcodebuild -exportArchive \
  -archivePath artifacts/release/BookQuotes-1.0-25.xcarchive \
  -exportPath artifacts/release/export-25 \
  -exportOptionsPlist artifacts/release/ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates
```

Result:

- App Store Connect analysis completed.
- Upload succeeded.
- Xcode reported: `Uploaded BookQuotes`.
- Xcode reported: `Uploaded package is processing.`
- Export succeeded.

## App Store Connect Verification

Command:

```bash
BUILD_NUMBER=25 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result:

- App ID: `6758091579`
- Build ID: `67d7c7df-1e1a-4cbb-8d2e-4c0ac6fd1095`
- Uploaded date: `2026-06-07T00:26:34-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` has `hasAccessToAllBuilds: true`
- Alastair Campbell (`acampbell193@googlemail.com`) remains in the internal `Test v1` beta group

## TestFlight Review Notes

Review should focus on clearly marked quote pages first:

- Clear colored underlines.
- Clear colored highlights.
- Clear margin marks adjacent to readable quote text.

Known limitations:

- Faint pencil marks, handwritten margin notes, and low-contrast real photos still need fixture-based characterization.
- Batch/capture queue paths still need review for remaining cloud extraction seams.
- Title/cover extraction still uses the existing cover extraction path and may continue to pull extra cover text until that behaviour is separately characterized.
