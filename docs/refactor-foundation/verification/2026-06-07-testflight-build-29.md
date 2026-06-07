# TestFlight Build 29 Verification

Build 29 was prepared to verify model-first quote extraction in TestFlight.

## Scope

- iOS build number: `29`
- Primary behavior change: quote capture now calls the remote Hugging Face-backed model before on-device OCR.
- Fallback behavior: on-device OCR is used only when the remote model fails or returns no usable quotes.
- Prompt change: bracketed or side-lined paragraphs must extract every readable line inside the marked span, not only an underline inside that span.
- Production Worker version: `68c35e56-9836-42f4-aa0f-0a79439d6290`
- Production Worker route: `api.bookquotes.uk/*`
- Cloudflare production secret: `HF_API_TOKEN` configured

## iOS Release Gate

Command:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testModelAssistedExtractorUsesRemoteModelBeforeLocalOCR \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testModelAssistedExtractorFallsBackToLocalOCRWhenRemoteModelFails \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testRemoteModelQuoteExtractorCallsModelAssistedProxyRoute \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests/testBuildPromptTreatsBracketedParagraphsAsCompleteMarkedPassages \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests/testBuildPromptRequestsBestEffortMarkedTextWhenBoundariesAreUncertain \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Passed.
- Runtime: `55.236` seconds.

## Archive and Upload

Archive command:

```bash
xcodebuild archive \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-1.0-29.xcarchive \
  -allowProvisioningUpdates
```

Result:

- `** ARCHIVE SUCCEEDED **`

Upload command:

```bash
xcodebuild -exportArchive \
  -archivePath artifacts/release/BookQuotes-1.0-29.xcarchive \
  -exportPath artifacts/release/export-29 \
  -exportOptionsPlist artifacts/release/ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates
```

Result:

- `Uploaded BookQuotes`
- `** EXPORT SUCCEEDED **`

## App Store Connect

Status command:

```bash
BUILD_NUMBER=29 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result:

- Build ID: `65b974ff-5ef7-4db9-9c05-54621fc92e2e`
- Uploaded date: `2026-06-07T07:09:10-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` remains configured with `hasAccessToAllBuilds: true`.
- Alastair Campbell remains in the internal `Test v1` beta group.

## TestFlight Checklist

Use build 29 to verify:

- bracketed/side-lined paragraph with an underline inside it returns the full marked span;
- clear underlined passage still returns the marked sentence;
- vertical margin-line marked paragraph returns the adjacent paragraph;
- multiple marked passages on the same page remain separate quote cards;
- remote extraction is no longer bypassed by a partial but high-confidence local OCR result.

## Remaining Risk

The simulator verifies orchestration and review UI behavior, but it does not perform live TestFlight image extraction against the Hugging Face route. The real quality check is the failing photographed page from build 28.
