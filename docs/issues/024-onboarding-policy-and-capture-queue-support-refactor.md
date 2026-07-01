# Onboarding Policy and Capture Queue Support Refactor

Status: `closed`

Priority: high

## Problem

The first onboarding/capture-queue refactors moved major presentation and processing work out of `OnboardingView` and `CaptureQueueManager`, but two forms of logic still had weak seams:

- `OnboardingView` still directly decided initial onboarding step and sign-in continuation routing.
- `CaptureQueueManager` still directly owned retry-delay calculation, repeated item fetch descriptors, and status-count aggregation.

These are small decisions, but they are high-leverage foundations for future onboarding/paywall and offline queue behavior changes.

## Acceptance Criteria

- [x] Characterize capture queue behavior before production edits.
- [x] Attempt onboarding simulator characterization before production edits and record runner result.
- [x] Add pure tests for onboarding flow routing decisions.
- [x] Add pure tests for capture queue retry-delay and queue-stat aggregation behavior.
- [x] Preserve onboarding initial step behavior for normal launch and App Store/TestFlight media subscription screen launch.
- [x] Preserve sign-in continuation behavior with subscriptions enabled/disabled.
- [x] Preserve queue add/remove/retry/cancel/cleanup behavior and stats publishing.
- [x] Preserve retry delay values: `5`, `30`, and `120` seconds with clamping.
- [x] Keep `OnboardingView.swift` and `CaptureQueueManager.swift` below 500 LOC.
- [x] Build passes.
- [x] Focused unit and queue characterization tests pass after refactor.
- [x] Architecture and verification docs record module ownership, LOC delta, test commands, and residual simulator risk.

## Outcome

2026-06-30:

- Added `BookQuotes/Features/Onboarding/OnboardingFlowPolicy.swift`.
- Added `BookQuotes/Services/CaptureQueueSupport.swift`.
- Added `BookQuotesTests/Unit/Utilities/OnboardingFlowPolicyTests.swift`.
- Added `BookQuotesTests/Unit/Services/CaptureQueueSupportTests.swift`.
- `OnboardingView` now delegates initial-step and post-sign-in routing decisions to `OnboardingFlowPolicy`.
- `CaptureQueueManager` now delegates retry delay selection, item descriptor creation, pending-item descriptor creation, and stats aggregation to `CaptureQueueSupport`.

## LOC Result

- `OnboardingView.swift`: 154 LOC -> 168 LOC.
- `OnboardingFlowPolicy.swift`: 21 LOC.
- `CaptureQueueManager.swift`: 416 LOC -> 378 LOC.
- `CaptureQueueSupport.swift`: 59 LOC.

## Residual Risk / Next Slice

- `OnboardingFlowTests` still cannot be used reliably in this environment because the XCTest UI runner hangs/fails during bootstrap before app assertions.
- `CaptureQueueProcessing` still calls the concrete `GeminiService`; extraction success/failure should get a protocol seam before changing queued extraction behavior.
- A future queue slice should characterize retry scheduling with a controllable clock rather than waiting on real delays.
