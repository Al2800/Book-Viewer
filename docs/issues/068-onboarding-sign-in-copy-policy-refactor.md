# Issue 068: Onboarding Sign-In Copy Policy Refactor

Status: `closed`

## Context

`OnboardingStepViews.swift` still mixed sign-in step presentation with the deterministic copy decision for subscription, cloud-sync, and local-library release configurations.

That copy is product-facing and should be characterized independently before further onboarding step refactors.

## Acceptance Criteria

- [x] Characterize sign-in copy when subscriptions are enabled.
- [x] Characterize sign-in copy when subscriptions are disabled and cloud sync is enabled.
- [x] Characterize sign-in copy when subscriptions and cloud sync are disabled.
- [x] Move sign-in copy selection out of `OnboardingStepViews.swift`.
- [x] Keep production behavior using `AppReleaseConfiguration`.
- [x] Keep `OnboardingStepViews.swift` below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused onboarding tests when the local Xcode runner is healthy.
- [x] Run simulator onboarding smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Features/Onboarding/OnboardingSignInCopyPolicy.swift`.
- Added `BookQuotesTests/Unit/Utilities/OnboardingSignInCopyPolicyTests.swift`.
- `OnboardingSignInStepView` now displays `copyPolicy.description`, defaulting to `.current`.

## Residual Risk / Next Slice

- `OnboardingStepViews.swift` still owns multiple screen compositions, but deterministic copy branching now has a dedicated test seam.
- Further step-view extraction should target one visible section at a time, with simulator smoke once CoreSimulatorService is available.

## Verification

- Focused onboarding/capture queue characterization gate on 2026-07-01:
  - 84 tests executed.
  - 0 failures.
- Broad unit gate on 2026-07-01:
  - 548 tests executed.
  - 0 failures.
- Manual onboarding reset simulator smoke:
  - App launched with `--uitesting --reset-onboarding --skip-auth`.
  - Screenshot showed the onboarding welcome screen.
