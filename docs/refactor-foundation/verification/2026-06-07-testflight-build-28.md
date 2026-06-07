# TestFlight Build 28 Verification

Build 28 was prepared to exercise the model-assisted quote extraction path in TestFlight.

## Scope

- iOS build number: `28`
- Backend route under test: `POST https://api.bookquotes.uk/api/extract-quotes-hf`
- Extraction path: on-device OCR and mark selection first, then Hugging Face vision fallback through the Cloudflare Worker when local extraction is empty or low confidence.
- Production Worker version: `68c35e56-9836-42f4-aa0f-0a79439d6290`
- Production Worker route: `api.bookquotes.uk/*`
- Cloudflare production secret: `HF_API_TOKEN` configured

## Backend Gate

Command:

```bash
cd backend
npx vitest run && npm run typecheck
```

Result:

- Passed.
- 4 backend test files passed.
- 16 backend tests passed.
- TypeScript typecheck passed.

Production health check:

```bash
curl -sS https://api.bookquotes.uk/health
```

Result:

```json
{"status":"ok","version":"1.0.0"}
```

## iOS Release Gate

Command:

```bash
xcodebuild test -quiet \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Passed.
- Runtime: `60.828` seconds.

## Archive and Upload

Archive command:

```bash
xcodebuild archive \
  -project BookQuotes.xcodeproj \
  -scheme BookQuotes \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath artifacts/release/BookQuotes-1.0-28.xcarchive \
  -allowProvisioningUpdates
```

Result:

- `** ARCHIVE SUCCEEDED **`

Upload command:

```bash
xcodebuild -exportArchive \
  -archivePath artifacts/release/BookQuotes-1.0-28.xcarchive \
  -exportPath artifacts/release/export-28 \
  -exportOptionsPlist artifacts/release/ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates
```

Result:

- `Uploaded BookQuotes`
- `** EXPORT SUCCEEDED **`

## App Store Connect

Status command:

```bash
BUILD_NUMBER=28 node scripts/appstoreconnect_status.js --set-encryption-false
```

Result:

- Build ID: `502cb29c-d3f5-47f3-bf2a-95c51a46f440`
- Uploaded date: `2026-06-07T06:27:35-07:00`
- Processing state: `VALID`
- Encryption status: `usesNonExemptEncryption: false`
- Internal beta group `Test v1` remains configured with `hasAccessToAllBuilds: true`.
- Alastair Campbell remains in the internal `Test v1` beta group.

## TestFlight Checklist

Use build 28 to verify the model-assisted extraction path on real book pages:

- clear underlined passage;
- faint pencil underline;
- vertical margin-line marked paragraph;
- multiple marked passages on the same page;
- difficult page curvature or partial OCR line breaks;
- comparison with build 27 for repeated-line or partial-line extraction failures.

## Billing Note

The model inference path uses Hugging Face billing because the Worker authenticates to Hugging Face with `HF_API_TOKEN` and calls the Hugging Face router. Cloudflare should only incur normal Worker, KV, and request processing costs for this route. The implementation does not call Cloudflare Workers AI.

## Caveat

Automated tests verify request shaping, response parsing, fallback behavior, and the existing local extraction flows. They do not perform a live authenticated app-session request against Hugging Face from TestFlight. The final quality check for marked-page extraction must happen on-device through build 28.
