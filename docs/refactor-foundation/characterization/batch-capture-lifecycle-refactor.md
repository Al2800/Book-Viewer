# Batch Capture Lifecycle Refactor Characterization

Date: 2026-06-06

Issue: `docs/issues/003-batch-capture-view-lifecycle-refactor.md`

## Baseline Behaviour

This slice preserves the existing batch capture behaviour while extracting deterministic lifecycle decisions and presentation-only subviews:

- empty sessions cannot finish;
- non-empty sessions show the existing finish confirmation from either Done or cancel;
- empty-session cancel still calls the cancel callback immediately;
- capture-in-progress still gates duplicate captures;
- offline queue completion shows the existing explicit confirmation sheet only when pages were queued;
- page-status copy remains unchanged for empty, singular, and plural page counts;
- thumbnail tap opens the detail sheet;
- removing a page from the detail sheet decrements the session page count;
- capture preprocessing remains in the existing detached task;
- offline queueing remains in the existing async queue loop.

## Characterization Added

`BatchCaptureLifecycleStateTests` covers:

- status text for empty, singular, and plural page counts;
- finish command decisions for empty and non-empty sessions;
- cancel command decisions for empty and non-empty sessions;
- offline queue completion decisions for zero and non-zero queued counts.

`BatchCaptureFlowTests.testBatchCapture_ThumbnailDetail_CanRemoveCapture` was added to cover the moved thumbnail-detail presentation path:

- opens batch capture through the Capture tab;
- captures a mocked test image;
- opens the thumbnail detail sheet;
- taps `Remove Page`;
- verifies the page count returns to zero.

## Extracted Modules

- `BatchCaptureLifecycleState.swift`: pure lifecycle state and commands for capture-in-progress, finish, cancel, status text, and offline queue confirmation decisions.
- `BatchCaptureSupplementaryViews.swift`: thumbnail view, capture detail sheet, offline queue confirmation sheet, deprecated offline toast, and previews.

## Performance-Sensitive Assumptions

The refactor deliberately did not move image preprocessing, thumbnail creation, disk IO, or queue insertion into new abstractions. Those operations remain exactly where they were:

- crop/document-detection/preprocess/thumbnail/disk IO remains inside `Task.detached(priority: .userInitiated)`;
- queue insertion remains async through `CaptureQueueManager.addToQueue`;
- SwiftUI state updates after queue completion remain on `MainActor`.
