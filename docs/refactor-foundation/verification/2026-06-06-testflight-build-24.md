# TestFlight Build 24 Verification

## Scope

Goal: ship a diagnostic TestFlight build after the build 23 quote-extraction recurrence report, so TestFlight review can distinguish real no-quote extraction from auth, subscription, proxy, parsing, or network failures.

## Build 24 Changes

- Failed extraction pages now show `Extraction Failed` with the captured error message instead of collapsing into `No Quotes Found`.
- Pending extraction pages are failed immediately when extraction cannot start because network is unavailable.
- Mock-camera simulator extraction now returns deterministic mock quotes, so the UI smoke does not depend on live Gemini/auth.
- The quote-capture UI smoke now fails unless extracted quote controls appear and `Save All` is enabled.

Production Gemini/proxy extraction remains unchanged in this build.

## Build Settings

Observed app target settings before archive:

- Bundle identifier: `com.acampbell.bookquotes`
- Marketing version: `1.0`
- Build number: `24`
- Team: `92XJSN32W4`
- Signing style: Automatic

The test targets kept their existing internal build numbers.

## Focused Release Gate

Command:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Passed.
- Runtime: `56.891` seconds.

Covered:

- Page-capture characterization.
- Quote-extraction prompt invariants.
- Extraction review processing summary for failed pages versus completed empty pages.
- Mock-camera extraction review with editable quote controls.
- Quote editor text editing.

## Archive

Command:

```bash
xcodebuild archive -project BookQuotes.xcodeproj -scheme BookQuotes -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-1.0-24.xcarchive \
  -allowProvisioningUpdates
```

Result:

- Archive succeeded.
- Archive bundle identifier: `com.acampbell.bookquotes`
- Archive version: `1.0`
- Archive build: `24`

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
  -archivePath artifacts/release/BookQuotes-1.0-24.xcarchive \
  -exportPath artifacts/release/export-24 \
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
BUILD_NUMBER=24 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result:

- App ID: `6758091579`
- Build ID: `c31545d4-d867-454c-b501-e6efa5ffc5bf`
- Uploaded date: `2026-06-06T14:26:25-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` has `hasAccessToAllBuilds: true`
- Alastair Campbell (`acampbell193@googlemail.com`) remains in the internal `Test v1` beta group

## TestFlight Review Notes

If quote extraction still fails in build 24, the review screen should now surface the real failure text. A subscription-related message means the sandbox user needs an active trial/subscription and a successful subscription sync before `/api/extract-quotes` is allowed.

If a clearly marked page still reaches `No Quotes Found`, the next diagnostic step is to compare that exact image against the proxy/model response, because the app will then be receiving a successful empty extraction rather than a masked failure.
