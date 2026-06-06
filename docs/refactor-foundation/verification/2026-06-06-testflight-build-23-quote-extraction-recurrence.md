# TestFlight Build 23 Quote Extraction Recurrence

## Scope

Issue: `007-testflight-build-22-quote-extraction-empty-results`

Build 23 still reports no quote returns during TestFlight review. This diagnostic pass focused on the app-side feedback loop and the extraction review presentation.

## Finding

The previous fix stopped empty quote arrays from being stored as successful extraction results, but the review UI still collapsed failed pages into the generic `No Quotes Found` state whenever there were no editable quotes.

That meant these cases were indistinguishable to the user:

- Valid model response with no marked/readable text.
- Proxy/auth/network failure.
- Gemini parsing failure.
- Gemini returning `quotes: []` for a page the user expected to contain marked text.

The simulator smoke also only checked that `Review Extractions` appeared. It did not require editable extracted quote controls, so it could pass even when no quote content was returned.

## Changes

- Added `ExtractionReviewProcessingSummary` and `ExtractionReviewCaptureStatusSnapshot` as a small characterization seam for review processing outcomes.
- Updated `ExtractionReviewView` to show `Extraction Failed` with the captured error message when pages fail.
- Updated no-network startup handling so pending pages are failed instead of staying indefinitely in processing.
- Added deterministic UI-test quote extraction under `--uitesting --mock-camera`, avoiding live Gemini/auth dependence for simulator acceptance.
- Tightened `testExtractionReview_DisplaysExtractedQuotes` so it fails unless extracted quote controls and enabled `Save All` are present.

## Verification

Focused characterization and UI smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testQuoteEditor_CanEditText
```

Result:

- Passed.
- Runtime: `55.539` seconds.

Prompt/page invariant plus UI route:

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
- Runtime: `54.028` seconds.

## Remaining Diagnostic Need

This fixes the local feedback loop and the app-side masking of extraction failures. It does not yet prove the real TestFlight model/proxy extraction is returning quotes for the user's marked pages.

Next TestFlight build should surface the actual failure text if extraction still fails. If it still returns `No Quotes Found` for a clearly marked page, compare the failing image and proxy/model response directly.

## Backend Note

The backend worker requires both:

- a valid session token; and
- `hasActiveSubscription(userId) == true`.

The quote endpoint returns `402 SUBSCRIPTION_REQUIRED` before Gemini extraction when the worker cannot find an active subscription/trial record in KV/App Store sync state.

This is a plausible cause for the TestFlight symptom because the user reported signing in, but signing in alone does not unlock `/api/extract-quotes`. Build 23 masked that failure as a no-quotes state. The patched review screen should show `A subscription is required to continue` if that is the actual failure.
