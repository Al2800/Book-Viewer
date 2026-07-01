# Issue 041: Onboarding Completion Action Refactor

Status: closed

## Problem

`OnboardingView` directly performed the completion sequence: mark the session as completing and persist the onboarding/coaching flags. That behavior is small, but it is the handoff between the UI flow and persisted first-run state, so it should be characterized outside SwiftUI before future onboarding changes.

The view should keep UI-only side effects such as haptics, callback invocation, and dismissal. The deterministic completion state transition should live behind a small module.

## Acceptance Criteria

- Characterize onboarding completion behavior before production edits.
- Preserve marking `OnboardingSessionState.isCompleting`.
- Preserve setting `hasCompletedOnboarding`.
- Preserve setting `showFirstCaptureCoaching`.
- Keep haptics, callback, and dismissal in `OnboardingView`.
- Keep `OnboardingView.swift` below 500 LOC.
- Run focused red-green tests for the extracted module.
- Run nearby onboarding characterization tests.
- Run simulator build.
- Attempt onboarding simulator UI smoke and record runner result.
- Update architecture and refactor-foundation docs.

## Result

- Added `BookQuotes/Features/Onboarding/OnboardingCompletionAction.swift`.
- Added `BookQuotesTests/Unit/Utilities/OnboardingCompletionActionTests.swift`.
- Updated `OnboardingView.completeOnboarding()` to delegate deterministic state/persistence work to `OnboardingCompletionAction`.

## LOC Result

- `BookQuotes/Features/Onboarding/OnboardingView.swift`: 160 LOC -> 158 LOC.
- `BookQuotes/Features/Onboarding/OnboardingCompletionAction.swift`: 14 LOC.

The view remains well below the 500 LOC target. The new module is intentionally small but not a pass-through: it is the single seam for completion state plus persisted first-run flags.

## Verification

- Focused red test confirmed missing completion action module before implementation:
  - `BookQuotesTests/OnboardingCompletionActionTests`
- Focused green test passed:
  - `BookQuotesTests/OnboardingCompletionActionTests`
- Nearby onboarding characterization passed:
  - `BookQuotesTests/OnboardingCompletionActionTests`
  - `BookQuotesTests/OnboardingCompletionStoreTests`
  - `BookQuotesTests/OnboardingSessionStateTests`
  - `BookQuotesTests/OnboardingFlowPolicyTests`
  - `BookQuotesTests/OnboardingAuthSkipPolicyTests`
- Simulator build passed.
- Onboarding UI smoke attempted:
  - `BookQuotesUITests/OnboardingFlowTests/testOnboarding_WelcomeCarousel_DisplaysAllPages`
  - Result: failed before app assertions because the XCTest runner timed out waiting for the AX loaded notification.

## Residual Risk / Next Slice

- `OnboardingPaywallViews.swift` and `OnboardingStepViews.swift` are still the largest onboarding files, but both remain below 500 LOC.
- Further onboarding work should be driven by product behavior changes or UI smoke repair rather than splitting these files only for size.
