# Onboarding and Capture Queue Modular Refactor

Status: `closed`

Priority: high

## Problem

`OnboardingView.swift` was 774 LOC and mixed flow coordination with welcome carousel presentation, marking setup presentation, embedded paywall logic, media plan cards, completion, and previews.

`CaptureQueueManager.swift` was 568 LOC and mixed queue lifecycle/processing with support value types, user-facing queue errors, and shared-instance wiring.

These files were priority refactor targets because they had high LOC and complexity proxies, and they sit on user-visible onboarding and offline capture processing paths.

## Acceptance Criteria

- [x] Existing onboarding UI flow is characterized on the simulator before production edits.
- [x] Existing queue manager unit/integration behaviour is characterized before production edits.
- [x] Existing tests remain unchanged for this slice; production code must preserve tested behaviour.
- [x] Extracted modules own real behaviour/presentation, not single-line pass-through wrappers.
- [x] `OnboardingView.swift` moves below 500 LOC.
- [x] `CaptureQueueManager.swift` moves below 500 LOC.
- [x] Simulator onboarding UI smoke passes after extraction.
- [x] Queue unit/integration characterization passes after extraction.
- [x] Architecture and verification docs record new module ownership, test commands, LOC delta, and residual risk.

## Outcome

2026-06-14:

- Added `BookQuotes/Features/Onboarding/OnboardingWelcomeViews.swift`.
- Added `BookQuotes/Features/Onboarding/OnboardingMarkingViews.swift`.
- Added `BookQuotes/Features/Onboarding/OnboardingPaywallViews.swift`.
- Kept `OnboardingView` as the step coordinator for welcome, sign-in, subscription, marking setup, and completion.
- Added `BookQuotes/Services/CaptureQueueTypes.swift`.
- Added `BookQuotes/Services/CaptureQueueShared.swift`.
- Kept `CaptureQueueManager` as the actor that owns queue lifecycle, item mutation, processing, retry scheduling, stats updates, and network observation.

## LOC Result

- `OnboardingView.swift`: 774 LOC -> 384 LOC.
- `OnboardingWelcomeViews.swift`: 67 LOC.
- `OnboardingMarkingViews.swift`: 51 LOC.
- `OnboardingPaywallViews.swift`: 273 LOC.
- `CaptureQueueManager.swift`: 568 LOC -> 475 LOC.
- `CaptureQueueTypes.swift`: 66 LOC.
- `CaptureQueueShared.swift`: 23 LOC.

## Residual Risk / Next Slice

- `OnboardingPaywallViews.swift` is still presentation-heavy at 273 LOC, but below target and covered by onboarding UI flow.
- `CaptureQueueManager.swift` is below target but still owns processing and retry orchestration. A deeper processor seam should only be introduced with focused characterization for successful extraction, failed extraction, retry scheduling, cancellation, and offline/online transition behaviour.
