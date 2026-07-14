# 106 - Eliminate false-green UI test skips

Status: in progress
Area: XCUITest / Release Gate
Priority: high (release blocker 15)

## Problem

The full UI target contains 33 `XCTSkip` branches. Several skip when a required application control, navigation route, fixture, editor, review, or save action is missing. Those conditions conceal regressions by reporting a skip instead of a failure. Only genuine environment constraints, such as unavailable physical camera hardware, may remain skips and must be explicitly reported.

## Acceptance Criteria

- [ ] Replace skips caused by missing application UI, fixtures, navigation, or save actions with failing assertions.
- [ ] Make mocked camera and seeded-data dependencies deterministic so workflow tests do not skip because setup did not arrive.
- [ ] Retain skips only for verified simulator or device limitations, with a clear reason and separate reporting.
- [ ] Run the full UI target with zero false-green skips and investigate every remaining failure.
- [ ] Record the final pass, failure, and genuine-environment skip counts in release evidence.

## Initial Inventory

- `BatchCaptureFlowTests`: 14 skip sites (resolved; 0 remaining).
- `CoverCaptureFlowTests`: 5 skip sites (resolved; 0 remaining).
- `QuoteCaptureFlowTests`: 11 skip sites (resolved; 0 remaining).
- `LibraryManagementTests`: 1 skip site (resolved; 0 remaining).
- `OnboardingFlowTests`: 2 skip sites.

## Verification

- Run each affected workflow individually after replacing its skips.
- Run the full UI target on phone and iPad simulators.
- Preserve `xcresult` bundles and distinguish product failures from documented simulator limitations.

## Progress

- [x] `QuoteCaptureFlowTests`: replaced all 11 false-green skip branches with deterministic fixtures and failing workflow assertions.
- [x] The mocked session fixture now honours low-confidence mode, so readers' visible confidence warning is covered instead of being an unreachable test case.
- [x] The direct book-to-capture, image review, provenance, edit, save, cancellation, page-number, and low-confidence journeys are covered by strict assertions.
- [x] `BatchCaptureFlowTests`: replaced all 14 false-green skip branches with strict page-count, thumbnail, draft, cancellation, and processing assertions.
- [x] Batch thumbnails are now accessible buttons with page labels, so readers using VoiceOver can open a captured page for review or removal.
- [x] The batch process route uses deterministic UI-test extraction only under the explicit mock scenario, allowing the real capture-to-review handoff to be exercised without network access.
- [x] `CoverCaptureFlowTests`: replaced all 5 false-green skip branches with strict capture-mode, crop-review, metadata, save, cancellation, and camera-permission assertions.
- [x] Cover capture now presents crop review from the captured image itself, preventing the review from being lost when capture and presentation state update together.
- [x] Cover barcode framing, instructions, and manual-entry actions have stable accessibility identifiers and reader-facing labels.
- [x] The explicit UI-test cover fixture supplies deterministic local metadata only while mocked camera testing is enabled; production cover analysis remains unchanged.
- [x] `LibraryManagementTests`: replaced the false-green delete skip with strict list-row, action-menu, destructive-confirmation, and cancellation assertions.
- [x] Book deletion now uses a native alert rather than a popover-style confirmation, preserving an explicit visible Cancel action for an irreversible operation on every size class.

## Evidence

- Targeted regression: `testCaptureFromBook_ShowsCaptureView`, `testLowConfidenceExtraction_ShowsReducedConfidence`, and `testQuoteEditor_CanEditText` passed on iPhone 17 (iOS 26.5).
- Full quote capture workflow: 13 passed, 0 failed, 0 skipped on iPhone 17 (iOS 26.5). Result bundle: `/Users/skyhub/Library/Developer/Xcode/DerivedData/BookQuotes-avxqmbzwmqonovbvenamjvakwlyv/Logs/Test/Test-BookQuotes-2026.07.14_16-40-53-+0100.xcresult`.
- Targeted batch regression: thumbnail discovery/removal, multi-page capture, processing, and draft resumption passed together on iPhone 17 (iOS 26.5).
- Full batch workflow: 12 passed, 0 failed, 0 skipped on iPhone 17 (iOS 26.5). Result bundle: `/Users/skyhub/Library/Developer/Xcode/DerivedData/BookQuotes-avxqmbzwmqonovbvenamjvakwlyv/Logs/Test/Test-BookQuotes-2026.07.14_17-30-28-+0100.xcresult`.
- Targeted cover regressions: test-cover capture, shutter capture-to-crop, and saving a captured cover each passed on iPhone 17 (iOS 26.5).
- Full cover workflow: 11 passed, 0 failed, 0 skipped on iPhone 17 (iOS 26.5). Result bundle: `/tmp/BookQuotes-CoverCapture-full.xcresult`.
- Full Library management workflow: 7 passed, 0 failed, 0 skipped on iPhone 17 (iOS 26.5). Result bundle: `/tmp/BookQuotes-LibraryManagement-full.xcresult`.
