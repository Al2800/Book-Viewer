# TestFlight Build 27 Verification

## Scope

Goal: ship quote grouping fixes after build 26 extracted text but fragmented one marked passage into many repeated quote cards.

Build 27 keeps the on-device OCR/mark-detection path and improves deterministic grouping before any model-based cleanup is considered.

## Build 27 Changes

- `QuoteMarkTextSelector` now deduplicates underline fragments that select the same OCR line.
- Adjacent underlined OCR lines are grouped into one quote candidate.
- Separate underlined sections split when there is a paragraph-sized vertical gap.
- Broken vertical margin-line strokes beside one paragraph are grouped into one quote candidate.
- Separate vertical margin marks on the same page produce separate quote candidates.

## Build Settings

Observed app target settings before archive:

- Bundle identifier: `com.acampbell.bookquotes`
- Marketing version: `1.0`
- Build number: `27`
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
- Runtime: `58.824` seconds.

Covered:

- Synthetic red underline extraction.
- Synthetic graphite/dark underline extraction.
- Plain printed text negative mark detection.
- Local real book photo fixture when present.
- Grouped adjacent underline fragments.
- Split separated underline blocks.
- Grouped broken margin-line paragraph marks.
- Split separated margin-line marks.
- Page-capture characterization.
- Extraction review quote state behaviour.
- Mock-camera extraction review with extracted quote controls.
- Quote editor text editing.

## Archive

Command:

```bash
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-1.0-27.xcarchive \
  -allowProvisioningUpdates
```

Result:

- Archive succeeded.
- Archive bundle identifier: `com.acampbell.bookquotes`
- Archive version: `1.0`
- Archive build: `27`

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
  -archivePath artifacts/release/BookQuotes-1.0-27.xcarchive \
  -exportPath artifacts/release/export-27 \
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
BUILD_NUMBER=27 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result:

- App ID: `6758091579`
- Build ID: `07ac82c4-64e1-449c-8ff1-460c32d94dac`
- Uploaded date: `2026-06-07T04:12:51-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` has `hasAccessToAllBuilds: true`
- Alastair Campbell (`acampbell193@googlemail.com`) remains in the internal `Test v1` beta group

## TestFlight Review Notes

Retest the build 26 over-fragmentation case:

- A multi-line underlined passage should produce one quote card, not one card per underline fragment.
- Two separated underlined sections on one page should produce two quote cards.
- A vertical margin line beside a paragraph should produce one paragraph quote.
- Two separated margin lines should produce two quote cards.

Known limitations:

- The exact build 26 over-fragmentation source photo is not yet in `local-fixtures/`.
- Margin-line grouping has selector tests but still needs real photographed margin-line fixtures.
- Faint highlights, curved pages, handwritten margin notes, and multi-page batch capture still need more real fixtures.
