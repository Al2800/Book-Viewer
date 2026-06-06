# Cover Camera And Crop Sections Verification

## Slice

Issue: `book-quote-cover-camera-crop-sections`

Goal: reduce `CoverCaptureView.swift` by extracting behavior-bearing crop, OCR, and cover-screen chrome modules while preserving cover capture behavior on the simulator.

## Characterization

- Added `CoverCropGeometryTests` before moving crop math.
- Reused existing `CoverOCRHeuristicsTests` as characterization before moving OCR heuristics.
- Reused `CoverCaptureFlowTests` as simulator acceptance for cover mode, test-cover navigation/save, and manual-entry behavior.

## Changes

- Added `CoverCropGeometry.swift` for viewport size, image scale, offset clamping, and crop-rect mapping.
- Added `CoverCropReviewView.swift` for the crop-review sheet.
- Added `CoverOCRHeuristics.swift` for OCR line sanitizing and title/author guessing.
- Added `CoverCaptureChrome.swift` for barcode overlay, processing overlay, mode switcher, bottom controls, and scan-line animation.
- Kept `CoverCaptureView.swift` as the camera/service/state orchestration shell.

## LOC

| File | LOC |
| --- | ---: |
| `CoverCaptureView.swift` | 443 |
| `CoverCaptureChrome.swift` | 154 |
| `CoverCropGeometry.swift` | 95 |
| `CoverCropReviewView.swift` | 205 |
| `CoverOCRHeuristics.swift` | 92 |
| `CoverExtractionOrchestrator.swift` | 33 |
| `CoverCropGeometryTests.swift` | 52 |

## Verification

- Red check: `CoverCropGeometryTests` failed before `CoverCropGeometry` existed.
- Focused unit: `CoverCropGeometryTests`, `CoverExtractionOrchestratorTests`, `CoverMetadataNormalizerTests`, `CoverOCRHeuristicsTests` passed 18 tests.
- Simulator acceptance: `CoverCaptureFlowTests` retained cover set passed 4 tests.

## Notes

- An exploratory direct crop-sheet UI test was not retained. The mock camera path did not reliably expose `Adjust Cover Crop`/`Use Crop` in the simulator during this slice, while the deterministic `Use Test Cover` path continues to guard the user-visible cover-to-book-edit flow.
- `detectCoverCrop(_:)` remains in `CoverCaptureView.swift` but is not currently called by the cover capture path. Treat it as a follow-up decision rather than moving dead code into a new module.
