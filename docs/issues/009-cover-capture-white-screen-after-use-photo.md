# 009 - Cover Capture White Screen After Use Photo

Status: closed
Area: Book registration
Priority: high

## Problem

During TestFlight build 22 cover photo capture, the app can freeze on a white screen after accepting the cropped cover. Relaunching returns to the expected flow.

## Characterization

- `CoverCaptureView` currently clears `capturedImage` while the full-screen crop review is still dismissing.
- The extraction task starts immediately from the crop review action.
- This creates a blank full-screen cover state during a transition and can overlap with the processing overlay/sheet state.

## Acceptance Criteria

- Accepting a cropped cover dismisses the crop review before clearing the captured image.
- Cover metadata processing starts from the full-screen cover dismissal path.
- The processing overlay remains visible only on the camera view, not as an empty full-screen cover.
- Simulator cover capture smoke tests still reach `BookEditView`.

## Verification

- Run targeted cover flow UI tests on simulator.
- Manually re-test photo capture, crop accept, processing, and edit sheet on simulator before TestFlight.

## Progress

2026-06-06:

- Changed `CoverCaptureView` so crop accept stores a pending cropped image, dismisses the full-screen crop review, and starts metadata processing from the dismissal path.
- This avoids clearing the full-screen cover content while it is still presented.
- Simulator smoke test confirmed the cover registration route still reaches `BookEditView`.
- Added `CoverCaptureCropLifecycleState` characterization tests so crop accept keeps the captured image available until dismissal consumes the pending crop.
- Added crop review button accessibility identifiers and a focused simulator probe for the crop accept route.
- Simulator cover capture smoke test still confirms the registration route reaches `BookEditView`.

## Final Verification

- `xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesTests/CoverCropGeometryTests`
  - Passed.
- `xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_CropAccept_DismissesReviewBeforeProcessing`
  - Completed without failure.
- `xcodebuild test -quiet -project BookQuotes.xcodeproj -scheme BookQuotes -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' -only-testing:BookQuotesUITests/CoverCaptureFlowTests/testCoverCapture_TestCoverButton_NavigatesToBookEdit`
  - Completed without failure.

## Residual Risk

- Real device camera capture still needs manual TestFlight confirmation because simulator camera mocking is not identical to the physical camera and crop interaction.
