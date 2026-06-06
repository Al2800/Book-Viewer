# Cover Camera And Crop Sections Characterization

## Scope

`CoverCaptureView.swift` currently owns:

- camera/permission preview switching;
- barcode overlay and scan-line animation;
- top mode switcher and bottom capture/manual controls;
- captured image state and crop-review sheet presentation;
- `CoverCropReviewView` presentation, gestures, viewport sizing, image offset clamping, and crop-rect calculation;
- extraction, OCR, ISBN lookup, processing state, and error presentation.

This slice targets the crop-review presentation, crop geometry, OCR heuristic locality, and cover capture screen chrome first. It does not change camera setup, barcode scanning, Gemini extraction, ISBN lookup, or save behavior.

## Current Crop Behaviour

| Area | Current behaviour |
| --- | --- |
| Viewport aspect | The crop frame is portrait, with height = width * 1.5 before height constraints. |
| Viewport width | Width is capped at 340 points and uses the available width minus horizontal `Spacing.xl * 2`. |
| Viewport height | Height is capped by available height minus 140, with a minimum candidate of 220 before the final aspect-corrected width is calculated. |
| Image scale | The image fills the viewport using `max(viewport.width / image.width, viewport.height / image.height)`, multiplied by zoom. |
| Drag offset | Offsets clamp to half of the overflow between displayed image size and viewport size. |
| Crop rect | The crop rectangle maps the visible viewport back into normalized image points, intersects with image bounds, then converts to pixels for `CGImage.cropping`. |
| Retake/cancel | Retake and toolbar Cancel both clear the captured image and dismiss the crop review. |
| Use Crop | Calls `onUse(croppedImage())`, dismisses the review, then cover metadata processing starts in the parent view. |

## Desired Seams

- `CoverCropGeometry`: pure sizing, scaling, offset clamping, and crop-rect calculations.
- `CoverCropReviewView`: focused crop-review SwiftUI surface using `CoverCropGeometry`.
- `CoverOCRHeuristics`: pure OCR line filtering and title/author guessing.
- `CoverCaptureChrome`: mode switcher, processing overlay, barcode overlay, and bottom controls.
- `CoverCaptureView`: owns captured image state and decides when to present crop review, but does not own crop math.

## Acceptance Notes

- Characterization tests should pin the crop geometry before production edits.
- Simulator cover flow should still reach crop/photo controls, test-cover edit, manual entry, and save paths.
- All extracted files should remain under 500 LOC.
- `CoverCaptureView.swift` should shrink without changing user-visible cover capture behaviour.

## Outcome

- `CoverCaptureView.swift`: 443 LOC after extraction.
- Extracted files: `CoverCaptureChrome.swift` 154 LOC, `CoverCropGeometry.swift` 95 LOC, `CoverCropReviewView.swift` 205 LOC, `CoverOCRHeuristics.swift` 92 LOC.
- Existing `detectCoverCrop(_:)` is currently not called by the cover capture path; it was not moved or deleted in this slice.
- Direct simulator coverage for the real crop-review sheet remains a follow-up testability gap because the retained deterministic cover UI tests drive the `Use Test Cover` path into `BookEditView`.
