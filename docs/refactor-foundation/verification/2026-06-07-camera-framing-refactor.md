# Camera Framing Refactor - 2026-06-07

## Scope

- Added `CameraFramingProfile` and `CameraFramingGeometry` for capture preview/crop policy.
- Changed quote-page and batch capture to use full-frame preview framing so margin marks and line endings are not hidden by aspect-fill preview crop.
- Kept cover capture on aspect-fill crop behavior, but routed crop through `ImagePreprocessor` off the main actor.
- Removed unused duplicate `CameraPreview.swift`.
- Removed unused crop/document-detection helpers from `CameraService`.

## LOC Result

- `CameraService.swift`: 640 LOC -> 490 LOC.
- `CameraFraming.swift`: 75 LOC.
- `CameraPreviewView.swift`: active preview wrapper, 134 LOC.

## Verification

Focused unit tests:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CameraFramingProfileTests \
  -only-testing:BookQuotesTests/ImagePreprocessorTests \
  -only-testing:BookQuotesTests/CameraServiceTests
```

Simulator smoke:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testImageReview_ShowsQualityIndicator \
  -only-testing:BookQuotesUITests/BatchCaptureFlowTests/testBatchCapture_CapturePhoto_IncrementsCounter \
  -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_CropAccept_DismissesReviewBeforeProcessing

xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testExtractionReview_DisplaysExtractedQuotes
```

Result:

- Passed.

Notes:

- Xcode still emits the repo's existing Swift concurrency, availability, and deprecation warnings.
- Simulator mock camera cannot validate real iPhone lens/focal-length feel. TestFlight/device verification remains required before treating this issue as closed.

## Minimal Guidance Update - 2026-06-09

User decision:

- Do not busy the image capture surface.
- Most users only need to know that the page should be visible.

Change:

- `CameraFramingProfile.quotePage.guidanceText` is now `Keep the page visible.`
- `QuoteCaptureView` uses the profile guidance text instead of a longer hardcoded instruction.

Verification:

```bash
xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:BookQuotesTests/CameraFramingProfileTests \
  -only-testing:BookQuotesUITests/QuoteCaptureFlowTests/testImageReview_ShowsQualityIndicator
```

Result:

- Passed.
