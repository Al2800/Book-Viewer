# Issue 067: Onboarding Media Subscription Plan Refactor

Status: `closed`

## Context

`OnboardingPaywallViews.swift` was the largest remaining onboarding module. It mixed the embedded paywall flow with deterministic fallback media plan copy and option-card presentation used when StoreKit products are unavailable in the App Store/TestFlight media subscription route.

This copy is product-facing and should be characterized before moving it out of the paywall coordinator.

## Acceptance Criteria

- [x] Characterize monthly fallback plan title, price, subtitle, period, and badge.
- [x] Characterize yearly fallback plan title, price, subtitle, period, and badge.
- [x] Characterize fallback plan display order.
- [x] Move fallback media plan model/presentation out of `OnboardingPaywallViews.swift`.
- [x] Preserve paywall product-loading, product-selection, media-plan fallback, trial button, and continuation behavior.
- [x] Keep `OnboardingPaywallViews.swift` below 500 LOC.
- [x] Register new production and test files in the Xcode project.
- [x] Update architecture and verification docs.
- [x] Run focused onboarding paywall tests when the local Xcode runner is healthy.
- [x] Run simulator onboarding smoke when CoreSimulatorService is available.

## Implementation

- Added `BookQuotes/Features/Onboarding/OnboardingMediaSubscriptionPlan.swift`.
- Added `BookQuotesTests/Unit/Utilities/OnboardingMediaSubscriptionPlanTests.swift`.
- Moved `MediaSubscriptionPlan` and `MediaSubscriptionOptionCard` out of `OnboardingPaywallViews.swift`.
- Kept `PaywallEmbeddedView` focused on StoreKit product state, selected plan/product state, trial start, error display, and continuation.

## Residual Risk / Next Slice

- `PaywallEmbeddedView` still directly owns product loading and purchase side effects. Extract only with a focused characterization seam around product selection/purchase outcomes.
- Full visual verification still requires the simulator route once CoreSimulatorService is available.

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
