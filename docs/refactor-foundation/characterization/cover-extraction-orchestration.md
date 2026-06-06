# Cover Extraction Orchestration Characterization

## Scope

`CoverCaptureView.swift` currently owns camera UI, crop review, barcode scanning, manual entry, Gemini cover extraction, Vision OCR fallback, metadata normalization, loading state, errors, and book-edit sheet presentation.

This slice extracts only the deterministic orchestration around cover metadata extraction. Camera capture, crop UI, Vision rectangle detection, Vision OCR implementation, API transport, manual-entry presentation, and ISBN lookup stay in the view or existing services for now.

## Current Extraction Decision Map

| Condition | Current behavior |
| --- | --- |
| Gemini succeeds with nonblank title and at least one author | Normalize Gemini result through `CoverMetadataNormalizer`; do not run OCR fallback. |
| Gemini succeeds with blank title | Run OCR fallback and let `CoverMetadataNormalizer` use OCR metadata when OCR title is nonblank. |
| Gemini succeeds with blank/empty author list | Run OCR fallback and let `CoverMetadataNormalizer` use OCR authors when available. |
| Gemini fails and OCR returns a nonblank title | Use OCR metadata directly. |
| Gemini fails and OCR title is blank | Return manual fallback metadata and preserve cover image data. |
| Final metadata title is blank in `processCapturedCover` | Open manual-entry metadata sheet and show the "Couldn’t read the cover details..." error. |

## Existing Side Effects

- `processCapturedCover` sets `isProcessing = true` before extraction and false afterwards.
- `extractedMetadata` is set for both successful metadata and manual fallback.
- Blank title after final metadata sets `errorMessage` and `showError`.
- The Gemini service is constructed from `authService` inside the view.
- OCR currently uses Vision directly inside `CoverCaptureView.extractCoverMetadataViaOCR`.

## Desired Seam

`CoverExtractionOrchestrator` should own:

- Gemini success/failure fallback decisions;
- whether OCR is needed;
- when Gemini output is normalized;
- when OCR output wins directly;
- when manual fallback is returned.

`CoverCaptureView` should own:

- constructing concrete Gemini and OCR closures;
- image JPEG data generation;
- processing/loading/error UI state;
- presenting `BookEditView`;
- camera/crop/barcode/manual-entry UI.

## Acceptance Notes

- The seam must use injected async closures so tests can characterize orchestration without camera, network, Vision, or SwiftUI.
- The seam should not know about API keys directly. Local API-key behavior remains inside `GeminiService`/`AuthService`; this slice only preserves the observable fallback behavior when Gemini succeeds or throws.
