# Verification: Onboarding Sign-In Copy Policy Refactor

Date: 2026-07-01

Issue: `068-onboarding-sign-in-copy-policy-refactor.md`

## Changed Files

- `BookQuotes/Features/Onboarding/OnboardingStepViews.swift`
- `BookQuotes/Features/Onboarding/OnboardingSignInCopyPolicy.swift`
- `BookQuotesTests/Unit/Utilities/OnboardingSignInCopyPolicyTests.swift`
- `BookQuotes.xcodeproj/project.pbxproj`
- `docs/issues/068-onboarding-sign-in-copy-policy-refactor.md`
- `docs/refactor-foundation/characterization/onboarding-sign-in-copy-policy-refactor.md`

## Expected Checks

- Focused unit tests:
  - `BookQuotesTests/OnboardingSignInCopyPolicyTests`
  - `BookQuotesTests/OnboardingFlowPolicyTests`
  - `BookQuotesTests/OnboardingSessionStateTests`
- Simulator smoke:
  - onboarding sign-in screen still renders the configured copy,
  - legal links and continue/sign-in controls still work.

## Local Result

Passed:

- `git diff --check`
- `plutil -lint BookQuotes.xcodeproj/project.pbxproj`
- LOC check:
  - `BookQuotes/Features/Onboarding/OnboardingStepViews.swift`: 244 LOC
  - `BookQuotes/Features/Onboarding/OnboardingSignInCopyPolicy.swift`: 25 LOC
  - `BookQuotesTests/Unit/Utilities/OnboardingSignInCopyPolicyTests.swift`: 41 LOC

Blocked:

- Focused `xcodebuild test` did not reach compilation. It failed while starting Xcode services with `DVTFilePathFSEvents: Failed to start fs event stream` and `Failed to get length of DARWIN_USER_CACHE_DIR`.
- Simulator smoke is blocked because `xcrun simctl list devices` cannot connect to `CoreSimulatorService` (`NSPOSIXErrorDomain Code=61 "Connection refused"`).

Keep issue 068 `in_progress` until focused onboarding tests and simulator smoke can be rerun.
