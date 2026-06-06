# Extraction Review Simulator Route Repair

Status: `closed`

Priority: high

## Problem

The existing extraction-review UI tests in `QuoteCaptureFlowTests` do not currently reach `ExtractionReviewView`. They skip with `Capture button not available` after the helper fails to open a seeded book detail/capture route.

This means extraction-review production refactors can be unit-characterized but do not yet have a reliable simulator acceptance path.

## Acceptance Criteria

- [ ] Characterize the current helper failure with a focused simulator run before changing test code.
- [ ] Repair the UI-test route without adding production-only behavior or broad app routing.
- [ ] The route reaches `Review Extractions` using seeded data and mock camera.
- [ ] `testExtractionReview_DisplaysExtractedQuotes` no longer skips for `Capture button not available`.
- [ ] `testQuoteEditor_CanEditText` no longer skips for `Capture button not available`.
- [ ] If the app requires a new UI-test-only launch seam, document why navigation through real UI is not viable first.
- [ ] Verification docs record the before/after simulator outcomes.

## Initial Target

Fix seeded library navigation or book-detail capture invocation in `QuoteCaptureFlowTests` so existing extraction-review tests can exercise the review screen directly.

## Progress

2026-06-06:

- Red baseline reproduced: `testExtractionReview_DisplaysExtractedQuotes` and `testQuoteEditor_CanEditText` both skipped with `Capture button not available`.
- Failure path: helper could not find `library_book_list_row`, tapped a generic Library cell fallback without reaching BookDetail, then tapped the Library add-book button while looking for a more menu.
- Repair approach: route extraction-review UI tests through the Capture tab quote-mode book selection, matching the already-stabilized capture-tab seam.
- Green verification: both `testExtractionReview_DisplaysExtractedQuotes` and `testQuoteEditor_CanEditText` passed without skips.
- Outcome: the simulator route now reaches `Review Extractions` using seeded data and mock camera.
