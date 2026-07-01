# Cover Capture Metadata Support Refactor - 2026-06-30

## Scope

- Extracted cover metadata support from `Features/BookRegistration/CoverCaptureView.swift` into `Features/BookRegistration/CoverCaptureMetadataSupport.swift`.
- Preserved `CoverCaptureView` ownership of camera setup, mode switching, crop review state, processing/error state, and sheet presentation.
- Preserved Gemini-first extraction, OCR fallback, ISBN lookup, and image orientation normalization behaviour.

## LOC Result

- `BookQuotes/Features/BookRegistration/CoverCaptureView.swift`: 486 LOC -> 333 LOC.
- `BookQuotes/Features/BookRegistration/CoverCaptureMetadataSupport.swift`: 164 LOC.

## Verification

Build:

```bash
xcodebuild build -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Result:

- Passed.

Focused cover crop/extraction/OCR tests:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CoverCropGeometryTests \
  -only-testing:BookQuotesTests/CoverExtractionOrchestratorTests \
  -only-testing:BookQuotesTests/CoverOCRHeuristicsTests
```

Result before edits:

- Passed.
- Runtime: `32.748` seconds.

Result after refactor:

- Passed.
- Runtime: `36.027` seconds.

Focused mocked-camera UI smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_CropAccept_DismissesReviewBeforeProcessing
```

Result before edits:

- Failed during UI runner/bootstrap with `Early unexpected exit, operation never finished bootstrapping`.

Result after refactor:

- Passed.
- Runtime: `72.133` seconds.

Notes:

- Xcode emitted existing project warnings and Vision Sendable warnings now located in `CoverCaptureMetadataSupport.swift`.
- No tests were edited for this slice.

## Residual Risk

- Because the baseline UI smoke failed before app assertions, visible cover capture behaviour is not fully covered by a clean before/after UI comparison.
- Real device camera framing still needs a separate characterization slice before UI or camera guidance changes.
