# Onboarding Step and Capture Queue Processing Refactor

Status: `closed`

Priority: high

## Problem

Issue 016 brought `OnboardingView.swift` and `CaptureQueueManager.swift` below the 500 LOC target, but both still carried mixed responsibilities:

- `OnboardingView.swift` still owned step routing and every step's screen composition.
- `CaptureQueueManager.swift` still owned queue lifecycle, retry scheduling, stats publication, image loading, marking prompt fetches, model extraction, quote creation, and completion/failure mutation.

This made future onboarding and offline queue changes harder to place precisely.

## Acceptance Criteria

- [x] Characterize capture queue behaviour before production edits.
- [x] Attempt onboarding simulator characterization before production edits and record the result.
- [x] Keep observable onboarding labels, buttons, skip paths, auth skip behaviour, legal sheet wiring, paywall continue path, marking setup path, and completion side effects unchanged.
- [x] Keep observable capture queue lifecycle, stats updates, retry scheduling, item completion/failure mutation, and quote creation behaviour unchanged.
- [x] `OnboardingView.swift` remains under 500 LOC and becomes the step coordinator rather than the step presenter.
- [x] `CaptureQueueManager.swift` remains under 500 LOC and delegates extraction transaction work to a focused processor.
- [x] Build passes after extraction.
- [x] Capture queue unit/integration characterization passes after extraction.
- [x] Simulator onboarding smoke is attempted after extraction and any runner limitation is documented.
- [x] Architecture and verification docs record new module ownership, test commands, LOC delta, and residual risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Features/Onboarding/OnboardingStepViews.swift`.
- Kept `OnboardingView` as the top-level coordinator for current step, legal sheet presentation, sign-in continuation, and onboarding completion side effects.
- Added `BookQuotes/Services/CaptureQueueProcessing.swift`.
- Kept `CaptureQueueManager` as the actor for lifecycle, add/remove/retry/cancel/cleanup, stats publication, network observation, and retry scheduling.

## LOC Result

- `OnboardingView.swift`: 384 LOC -> 154 LOC.
- `OnboardingStepViews.swift`: 255 LOC.
- `CaptureQueueManager.swift`: 475 LOC -> 416 LOC.
- `CaptureQueueProcessing.swift`: 91 LOC.

## Residual Risk / Next Slice

- The onboarding UI route could not be asserted in this environment because the XCTest UI runner failed before app assertions with `Timed out waiting for AX loaded notification`.
- `CaptureQueueProcessing` still calls the concrete `GeminiService`, so successful extraction remains hard to unit-test without a protocol seam or hermetic model/extraction fake.
- A follow-on queue slice should characterize success/failure processing with a testable extraction dependency before changing retry or processing behaviour again.
