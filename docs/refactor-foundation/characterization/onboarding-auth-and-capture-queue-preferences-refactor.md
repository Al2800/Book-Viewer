# Onboarding Auth and Capture Queue Preferences Refactor Characterization

Date: 2026-06-30

## Scope

This slice characterized two remaining policy decisions in the onboarding/capture-queue area:

- whether onboarding allows manual auth skip or automatic simulator auth skip;
- whether the capture queue automatically processes pending items.

The intent was not to add behavior. It was to move environment and persistence rules behind named modules so future changes have smaller test surfaces.

## Characterized Behavior

- Simulator builds allow manual auth skip even without `--skip-auth`.
- Device builds only allow manual auth skip when the skip-auth launch argument is active.
- Simulator builds auto-skip auth outside UI testing.
- UI testing disables simulator auto-skip so UI tests can assert the sign-in step.
- Device builds never auto-skip auth.
- Queue auto-processing defaults to enabled when `autoProcessQueue` is unset.
- Queue auto-processing follows the stored `autoProcessQueue` boolean when set.

## Red Step

Added `OnboardingAuthSkipPolicyTests` and `CaptureQueueProcessingPreferencesTests`.

The first focused run failed because `CaptureQueueProcessingPreferences` did not exist, confirming the test target was exercising the missing production module.

## Refactor

- Added `OnboardingAuthSkipPolicy` and injected it into `OnboardingView`.
- Added `CaptureQueueProcessingPreferences` and injected it into `CaptureQueueManager`.
- Kept the queue preference key in one place: `CaptureQueueProcessingPreferences.autoProcessQueueKey`.
- Preserved the actor-owned queue lifecycle in `CaptureQueueManager`.

## Verification

See `docs/refactor-foundation/verification/2026-06-30-onboarding-auth-and-capture-queue-preferences-refactor.md`.
