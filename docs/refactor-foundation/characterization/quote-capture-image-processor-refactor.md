# Quote Capture Image Processor Refactor Characterization

Date: 2026-06-30

Issue: `docs/issues/014-camera-preview-framing-and-guidance.md`

## Baseline Behaviour

`QuoteCaptureView` handled the full single-page capture sequence:

- Request/capture an image from `CameraService`.
- Read the preview size for any profile-driven visible-area crop.
- For quote-page capture, preserve the full frame because `CameraFramingProfile.quotePage.captureCropBehavior == .none`.
- For aspect-fill profiles, crop to the visible preview area when a preview size exists, falling back to the uncropped image if crop fails.
- Run document auto-crop.
- Run quality analysis with the lenient configuration.
- If quality analysis fails, keep the prepared image available for review, show an error, and still present the review sheet.

The behavior is important for issue `014` because the extraction model needs the same framed content the user intended to send, with margin marks and line endings preserved for quote pages.

## Characterization Tests

Added `QuoteCaptureImageProcessorTests` before the production module existed. The red state was a compile failure because `QuoteCaptureImageProcessor` was missing.

The tests characterize:

- Quote-page capture skips visible-area crop and keeps the full frame before document preparation and quality analysis.
- Aspect-fill capture crops the visible area before document preparation and quality analysis.
- Aspect-fill capture skips visible-area crop when preview size is unavailable.
- Quality-analysis failure still returns the prepared image and records the error rather than aborting review.

## Refactor Boundary

`QuoteCaptureImageProcessor` now owns image preparation and quality-analysis orchestration. `QuoteCaptureView` keeps UI state, haptics, camera calls, review presentation, extraction-review presentation, and user-visible error state.

This is a deep module because callers provide one image, one optional preview size, and one framing profile; the module hides crop-policy application, document preparation ordering, quality-analysis ordering, and non-fatal quality-analysis failure handling.
