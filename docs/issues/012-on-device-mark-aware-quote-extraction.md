# 012 - On-Device Mark-Aware Quote Extraction

Status: in_progress
Area: Quote capture
Priority: high

## Problem

Quote extraction currently depends on the Cloudflare/Gemini path, which is oversized for the product goal and creates avoidable blockers around API keys, backend deployment, subscription state, privacy, cost, and TestFlight validation.

The app should prefer a fully on-device extraction path that uses iPhone-native OCR and local mark detection to identify the text the user intended to save: underlined passages, highlighted passages, margin lines, margin notes, and the user-defined marking criteria already configured in the app.

Gemini should not be the default extractor for marked quote pages. A small local model may be useful for cleanup or classification, but it should not replace deterministic OCR and geometry as the foundation.

## Current Characterization

- Quote review currently calls `GeminiService.extractQuotes(from:markings:)` from `ExtractionReviewView`.
- `QuoteExtractionPromptBuilder` expresses the user's marking definitions for the Gemini prompt.
- `QuoteExtractionResult` and `ExtractedQuoteData` are the downstream data shape consumed by quote review and save flows.
- Cover registration already has a Vision OCR fallback inside the cover-capture path, plus `CoverOCRHeuristics` for local title/author cleanup.
- The quote-capture path does not yet have an equivalent local OCR seam for recognized text lines, bounding boxes, mark regions, or candidate grouping.
- Mock camera images already draw highlighted and underlined passages, so they can seed first characterization fixtures before real photographed fixtures are added.

## What to Build

Build an on-device quote extraction pipeline that can run without Cloudflare, Gemini, or a subscription gate:

```text
Captured page image
-> image normalization
-> Vision OCR text observations with bounding boxes
-> local detection of underline/highlight/margin marks
-> geometry-based matching from marks to nearby OCR text lines
-> candidate grouping into quote passages and margin notes
-> confidence scoring and editable review output
```

The pipeline should return the same quote-review data shape the app already expects so `ExtractionReviewView`, `PageCapture`, and quote saving can continue to work while the extraction implementation changes underneath.

## Acceptance Criteria

- [ ] A dedicated on-device quote extraction module exists behind a small public interface that accepts a page image plus enabled marking definitions and returns `QuoteExtractionResult` or an equivalent adapter into the existing review state.
- [ ] Apple Vision OCR is used for raw text recognition and exposes recognized text, confidence, and normalized bounding boxes to the quote extraction pipeline.
- [ ] The pipeline detects at least these mark families locally:
  - underline / double underline
  - highlighted text regions
  - margin line / vertical side mark
  - margin note / annotation text
- [ ] Mark detection is deterministic and testable separately from OCR.
- [ ] OCR line selection is based on geometry:
  - highlighted text selects OCR lines inside or overlapping the highlight region;
  - underline selects the OCR line immediately above or intersecting the underline;
  - margin line selects adjacent paragraph lines in the text column;
  - margin note text is captured separately from the quote body where possible.
- [x] User-defined `MarkingDefinition` records influence classification and display naming without requiring a prompt to a cloud model.
- [ ] Unmarked page text is excluded from extracted quote candidates.
- [ ] Multi-line marked passages are grouped into one quote candidate when line spacing and mark continuity indicate the same passage.
- [ ] Candidate confidence is derived from OCR confidence, mark/text geometry quality, and grouping certainty.
- [ ] Low-confidence or ambiguous candidates still appear in review for user correction rather than being silently discarded.
- [x] The extraction review screen can process a captured marked page with no network connection.
- [x] Cloud/Gemini extraction is removed from the default quote-capture path or placed behind an explicit fallback flag that is off by default.
- [x] Legal/privacy copy is updated so quote page extraction no longer claims images are sent to Gemini when the on-device path is active.
- [x] Existing manual quote-add and quote-edit flows remain unchanged.

## Characterization Plan

Before replacing the extractor, characterize the current desired behaviour with fixture-driven tests:

- [ ] Create synthetic fixture images for:
  - a single underlined passage;
  - a highlighted multi-line passage;
  - a margin-line marked paragraph;
  - a margin note next to a marked quote;
  - an unmarked page that should return no quotes.
- [ ] Use the existing mock camera image renderer where possible, then add real photographed fixtures once available.
- [ ] Record expected candidate quote text, marking type, margin note handling, and confidence band for each fixture.
- [ ] Add tests that assert downstream review receives editable quote data, not just that the review route opens.

## TDD / Implementation Plan

1. Add pure geometry tests for matching OCR line boxes to mark boxes.
2. Add pure mark-detection tests using synthetic images with known underline/highlight/margin shapes.
3. Add a Vision OCR adapter seam with tests around normalized bounding-box conversion and OCR-line sorting.
4. Add candidate grouping tests for single-line and multi-line passages.
5. Add an integration test using a fixture image that produces at least one `ExtractedQuoteData` without network access.
6. Switch the quote-capture path from `GeminiService` to the on-device extractor behind an injectable interface.
7. Keep Gemini fallback disabled by default until on-device extraction has been tested on real marked pages.

## Small Local Model Option

A small local model, such as an on-device Gemma variant, may be evaluated after the OCR/geometry pipeline exists.

Allowed local-model responsibilities:

- clean OCR line breaks;
- classify ambiguous candidate type;
- separate quote body from margin note text;
- remove obvious page headers, footers, or running titles from already-selected candidates.

Non-goals for the local model:

- deciding from the whole image which text is marked;
- replacing Vision OCR;
- sending page images or OCR text to a remote service;
- making extraction dependent on model availability.

## Verification Route

- Run focused unit tests for mark detection, OCR geometry, candidate grouping, and confidence scoring.
- Run simulator quote-capture UI tests with mock marked-page images and no network dependency.
- Run a manual simulator smoke using at least one known underlined/highlighted fixture.
- Run TestFlight with the user’s real marked pages and confirm quote extraction works without Cloudflare/Gemini availability.

## Refactor Impact

- This issue should create a deeper quote-extraction module rather than adding more logic to `ExtractionReviewView`.
- `GeminiService` should stop being the quote-capture default and become an optional fallback or cover-metadata-only dependency.
- `QuoteExtractionPromptBuilder` may become fallback-only or be retired for quote extraction.
- `ExtractionReviewView` should depend on an extraction interface, not a concrete cloud model service.
- Existing `QuoteExtractionResult` parsing and review state should be reused where possible to avoid unnecessary downstream churn.

## Blocked By

None - can start immediately.

## Related Issues

- `007-testflight-build-22-quote-extraction-empty-results.md`
- `002-extraction-review-view-modular-refactor.md`
- `006-extraction-review-simulator-route-repair.md`
- `008-cover-metadata-noisy-title-author-extraction.md`

## Progress

2026-06-07:

- Added the first on-device quote extraction tracer bullet.
- Introduced `OnDeviceQuoteExtractor` behind a small public interface returning the existing `QuoteExtractionResult` shape.
- Added `VisionPageTextRecognizer` for Apple Vision OCR line recognition.
- Added `PageMarkDetector` for local red underline, yellow highlight, and colored margin-mark region detection.
- Added `QuoteMarkTextSelector` for geometry-based mark-to-OCR-line matching.
- Wired `ExtractionReviewView` to the on-device extractor for quote pages and removed the network precondition from that review processing path.
- Updated mock-camera single quote image to draw readable underlined text so simulator smoke exercises Vision OCR instead of a cloud/mock result.
- Updated legal copy to distinguish on-device quote extraction from cloud-assisted cover/fallback extraction.

2026-06-07 follow-up:

- Build 25 TestFlight still failed on a real page with `No marked passages were found in the image`.
- The message confirms the app reached the on-device path, but the local mark detector did not identify any mark regions.
- Added graphite/dark underline characterization for low-saturation pencil-style marks.
- Added a plain printed text negative characterization so widening graphite detection does not make unmarked pages extract quotes.
- Expanded `PageMarkDetector` with a separate neutral underline path for thin, long, low-saturation marks.
- Added a local-only real book photo characterization test. The fixture image is stored under ignored `local-fixtures/` so copyrighted page photos stay out of the public repo.

2026-06-07 build 26 review follow-up:

- Build 26 extracted quote text, but fragmented the marked passage into many repeated quote cards.
- The symptom showed `13 Quotes` for a page where the user expected the six underlined lines to be treated as one marked passage.
- Added a selector-level regression where segmented underline marks across six adjacent OCR lines must produce one quote candidate.
- Updated `QuoteMarkTextSelector` to deduplicate underline fragments and group adjacent underlined OCR lines before returning candidates.
- Added quote-grouping rules for separate underlined sections so a paragraph gap splits one marked page into multiple quote candidates.
- Added vertical margin-line grouping so a broken margin stroke beside one paragraph produces one quote candidate.
- Added vertical margin-line split coverage so two separated margin marks on one page produce two quote candidates.

2026-07-15 custom-marking identity follow-up:

- Added a safe marking-definition snapshot containing the local definition ID and whether it is a system default.
- The deterministic on-device extractor now applies an enabled custom definition only when its visible mark family is unambiguous, retaining the reader-facing display name for review.
- Model-assisted output is resolved only against validated, enabled local definitions after parsing; no model response can supply or select a SwiftData definition ID.
- Cached capture results, extraction review, queued capture processing, and quote saving now preserve the resolved custom marking relationship.
- The review editor now uses a fixed-height native UIKit text editor so its margin-note field remains visible on compact screens, it reliably receives initial keyboard focus, and active edits are not overwritten by a stale SwiftUI update.

2026-07-15 local-first follow-up:

- Quote extraction now starts with on-device OCR regardless of consent, sign-in, subscription, or
  network availability. A successful local result never calls the hosted model.
- Remote quote extraction is now an explicit, consent-controlled recovery path: it is constructed
  only when Remote AI Processing is enabled and runs only after local OCR finds no candidate or
  encounters an error.
- Extraction Review no longer presents the Remote AI Processing sheet before processing a pending
  capture. The optional decision remains available in onboarding and Settings.
- The quote-capture UI regression now asserts that on-device review is not blocked by the remote
  consent sheet.

## Verification Results

Focused on-device extractor tracer:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testExtractsUnderlinedTextFromSyntheticPageWithoutNetwork
```

Result:

- Passed.

Quote-capture simulator smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes
```

Result:

- Passed.

Focused release gate:

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
- Runtime: `55.352` seconds.

Graphite underline follow-up:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests
```

Result:

- Passed.

Real uploaded page fixture:

```bash
xcodebuild test -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testRealBookFixtureExtractsUnderlinedPassageWhenProvided
```

Result:

- Passed with `local-fixtures/real-pages/british-are-coming-underlined-page.jpg`.
- The fixture is local-only and ignored by git.

Underline grouping follow-up:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorGroupsAdjacentUnderlineFragmentsIntoOneQuote
```

Result:

- Failed before the selector grouping fix.
- Passed after `QuoteMarkTextSelector` grouped adjacent underline selections.

Post-fix smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes
```

Result:

- Passed.

Quote grouping rules:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorGroupsAdjacentUnderlineFragmentsIntoOneQuote \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorSplitsSeparateUnderlineBlocksByParagraphGap \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorGroupsBrokenMarginLineBesideOneParagraph \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests/testSelectorSplitsSeparateMarginLinesByParagraphGap
```

Result:

- Passed.

Build 27 release gate:

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

Custom-marking identity regression:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/OnDeviceQuoteExtractorTests \
  -only-testing:BookQuotesTests/QuoteExtractionPromptBuilderTests \
  -only-testing:BookQuotesTests/QuoteSaveDraftTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests \
  -only-testing:BookQuotesTests/PageCaptureTests \
  -only-testing:BookQuotesTests/CaptureQueueStoreTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes
```

Result:

- Passed on 2026-07-15.
- Runtime: `49.802` seconds.

Quote-editor interaction regression:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests \
  -only-testing:BookQuotesTests/QuoteSaveDraftTests \
  -only-testing:BookQuotesTests/ExtractionReviewQuoteStateTests
```

Result:

- Passed on 2026-07-15: 20 tests, 0 failures, 0 skips; runtime `382.707` seconds.
- Retained result bundle: `/tmp/bookquotes-capture-regression-2026-07-15.xcresult`.
- `QuoteCaptureFlowTests/testQuoteEditor_CanEditText` also passed on iPad Air 11-inch (M4),
  iOS 26.5: 1 test, 0 failures, 0 skips; runtime `90.072` seconds.
- Retained result bundle: `/tmp/bookquotes-quote-editor-ipad-2026-07-15.xcresult`.

## Residual Risk

- This is a first tracer bullet, not the full issue.
- Real photographed pages with faint highlights, curved pages, mixed lighting, handwritten margin notes, and actual iPhone captures still need characterization fixtures.
- The current graphite support has been validated against one real page photo, but more fixtures are needed before declaring broad real-world coverage.
- The build 26 over-fragmentation screenshot is not yet backed by the original captured source page photo. The selector regression covers the observed shape, but the exact image should be added as another local fixture when available.
- Margin-line grouping is covered at the geometry selector seam, but still needs real photographed margin-line fixtures.
- Batch capture and capture queue paths may still contain cloud/Gemini extraction placeholders and should be reviewed before declaring quote extraction fully on-device across the whole app.
- A small local model has not been evaluated yet; the current slice is deterministic OCR plus geometry only.
