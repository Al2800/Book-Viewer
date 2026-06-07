# TestFlight Build 26 Verification

## Scope

Goal: ship the follow-up quote extraction fix after build 25 still failed on a real page with `No marked passages were found in the image`.

Build 26 keeps the on-device extraction path from build 25 and adds support for low-saturation graphite/dark underlines. The build is intended to validate the uploaded real book photo class where the marked quote is underlined in dark pencil/pen rather than a saturated color.

## Build 26 Changes

- `PageMarkDetector` now has a separate neutral underline path for thin, long, low-saturation marks.
- Synthetic graphite underline characterization was added.
- Plain printed text negative characterization was added to reduce false-positive risk.
- A local-only real book page fixture test was added. The fixture lives under ignored `local-fixtures/` and is not committed to the public repo.
- The uploaded real page photo passed the local fixture test before release.

## Build Settings

Observed app target settings before archive:

- Bundle identifier: `com.acampbell.bookquotes`
- Marketing version: `1.0`
- Build number: `26`
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
- Runtime: `60.251` seconds.

Covered:

- Synthetic red underline extraction.
- Synthetic graphite/dark underline extraction.
- Plain printed text negative mark detection.
- Local real book photo fixture when present.
- Page-capture characterization.
- Extraction review quote state behaviour.
- Mock-camera extraction review with extracted quote controls.
- Quote editor text editing.

## Real Fixture Check

Local fixture path:

```text
local-fixtures/real-pages/british-are-coming-underlined-page.jpg
```

Command:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testRealBookFixtureExtractsUnderlinedPassageWhenProvided
```

Result:

- Passed.
- The fixture is intentionally ignored by git.

## Archive

Command:

```bash
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-1.0-26.xcarchive \
  -allowProvisioningUpdates
```

Result:

- Archive succeeded.
- Archive bundle identifier: `com.acampbell.bookquotes`
- Archive version: `1.0`
- Archive build: `26`

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
  -archivePath artifacts/release/BookQuotes-1.0-26.xcarchive \
  -exportPath artifacts/release/export-26 \
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
BUILD_NUMBER=26 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result:

- App ID: `6758091579`
- Build ID: `fbcb1763-7d08-4151-86e1-d22b2d47ced7`
- Uploaded date: `2026-06-07T01:57:06-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` has `hasAccessToAllBuilds: true`
- Alastair Campbell (`acampbell193@googlemail.com`) remains in the internal `Test v1` beta group

## TestFlight Review Notes

Review should retest the real page style that failed build 25:

- Dark graphite/pencil/pen underlines.
- The uploaded `The British Are Coming` page with the underlined Chatham quote.
- Clear colored underlines/highlights from the build 25 review plan.

Known limitations:

- Only one real book photo has been characterized locally so far.
- Faint highlights, curved pages, handwritten margin notes, and multi-page batch capture still need more real fixtures.
- Title/cover extraction still uses the existing cover extraction path and may continue to pull extra cover text until that issue is separately characterized.
