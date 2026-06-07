# 012 - On-Device Mark-Aware Quote Extraction

Status: open
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
- [ ] User-defined `MarkingDefinition` records influence classification and display naming without requiring a prompt to a cloud model.
- [ ] Unmarked page text is excluded from extracted quote candidates.
- [ ] Multi-line marked passages are grouped into one quote candidate when line spacing and mark continuity indicate the same passage.
- [ ] Candidate confidence is derived from OCR confidence, mark/text geometry quality, and grouping certainty.
- [ ] Low-confidence or ambiguous candidates still appear in review for user correction rather than being silently discarded.
- [ ] The extraction review screen can process a captured marked page with no network connection.
- [ ] Cloud/Gemini extraction is removed from the default quote-capture path or placed behind an explicit fallback flag that is off by default.
- [ ] Legal/privacy copy is updated so quote page extraction no longer claims images are sent to Gemini when the on-device path is active.
- [ ] Existing manual quote-add and quote-edit flows remain unchanged.

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
