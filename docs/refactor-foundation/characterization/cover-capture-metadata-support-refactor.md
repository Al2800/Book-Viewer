# Cover Capture Metadata Support Characterization

Date: 2026-06-30

Issue: `docs/issues/023-cover-capture-metadata-support-refactor.md`

## Baseline Behaviour

This slice keeps cover capture behaviour intact while extracting metadata support code from the SwiftUI screen.

Cover capture behaviours retained:

- Photo mode captures an image, crops it to the visible preview region when needed, normalizes orientation, and presents crop review.
- Accepting crop review dismisses the review before cover processing starts.
- Cover processing uses Gemini first through `CoverExtractionOrchestrator`.
- OCR fallback remains available when Gemini fails or returns unusable metadata.
- OCR fallback sanitizes lines with `CoverOCRHeuristics` and splits authors with `CoverMetadataNormalizer`.
- Blank title after processing still shows the manual-entry error message.
- Barcode mode keeps ISBN scanner start/stop semantics and ISBN lookup.
- Manual entry still creates empty metadata to open the edit form.
- Test-cover path remains available in UI test mode and creates deterministic metadata.

## Characterization Used

Focused cover unit baseline:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CoverCropGeometryTests \
  -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests \
  -only-testing:BookQuotesTests/CoverOCRHeuristicsTests
```

Result before edits:

- Passed.
- Runtime: `32.748` seconds.

Focused mocked-camera UI smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_CropAccept_DismissesReviewBeforeProcessing
```

Result before edits:

- Failed before production edits during UI runner/bootstrap.
- Failure: `Early unexpected exit, operation never finished bootstrapping`.

## Extracted Module

- `CoverCaptureMetadataSupport.swift`: Gemini-first extraction orchestration, Vision OCR fallback, Vision rectangle crop detection support, orientation normalization, and ISBN lookup helper.

## Non-Goals

- No camera framing change.
- No copy or visible guidance change.
- No prompt/model change for cover metadata extraction.
- No change to tests to make this pass.
